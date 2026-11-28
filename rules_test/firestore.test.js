// Firestore security rules tests. Run from this folder with: npm test
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc, getDoc, setDoc, updateDoc, deleteDoc, getDocs, collection, query, where,
  serverTimestamp, Timestamp, setLogLevel,
} = require('firebase/firestore');

// Blocked writes are expected in these tests, so don't print each one.
setLogLevel('silent');

let env;

// People used in the tests.
const BUYER = 'b1';
const SELLER = 's1';
const SELLER2 = 's2';

const db = (uid) => (uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore());

// A listing with every field filled in, the way the app will save it.
function listing(overrides = {}) {
  return {
    sellerId: SELLER,
    status: 'published',
    title: 'Nice 3 bed house',
    description: 'Big yard',
    price: 250000,
    type: 'house',
    beds: 3,
    baths: 2,
    sqft: 1600,
    yearBuilt: 1998,
    lotSize: 0.25,
    address: '12 Main St',
    city: 'Atlanta',
    zip: '30303',
    location: { lat: 33.75, lng: -84.39, geohash: 'dn5bp' },
    amenities: ['garage'],
    photos: [],
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

const past = Timestamp.fromDate(new Date('2025-01-01'));
const inDays = (n) => Timestamp.fromDate(new Date(Date.now() + n * 86400000));

// Seed data with the rules turned off.
async function seed(fn) {
  await env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-housebusiness',
    firestore: { rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8') },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed(async (s) => {
    await setDoc(doc(s, 'users', BUYER), { name: 'Bob Buyer', role: 'buyer', photoUrl: null, createdAt: past });
    await setDoc(doc(s, 'users', SELLER), { name: 'Sam Seller', role: 'seller', photoUrl: null, createdAt: past });
    await setDoc(doc(s, 'users', SELLER2), { name: 'Sue Seller', role: 'seller', photoUrl: null, createdAt: past });
    await setDoc(doc(s, 'users', SELLER, 'private', 'contact'), { email: 's1@test.com', phone: null });
    await setDoc(doc(s, 'listings', 'pub'), listing({ createdAt: past, updatedAt: past }));
    await setDoc(doc(s, 'listings', 'draft'), listing({ status: 'draft', createdAt: past, updatedAt: past }));
  });
});

describe('users', () => {
  it('signed out people cannot read profiles', async () => {
    await assertFails(getDoc(doc(db(null), 'users', SELLER)));
  });

  it('logged in users can read a profile', async () => {
    await assertSucceeds(getDoc(doc(db(BUYER), 'users', SELLER)));
  });

  it('a new user can create their own profile', async () => {
    await assertSucceeds(setDoc(doc(db('new1'), 'users', 'new1'),
      { name: 'Nia', role: 'buyer', photoUrl: null, createdAt: serverTimestamp() }));
  });

  it('cannot create a profile for someone else', async () => {
    await assertFails(setDoc(doc(db('new1'), 'users', 'other'),
      { name: 'Nia', role: 'buyer', photoUrl: null, createdAt: serverTimestamp() }));
  });

  it('role must be buyer or seller', async () => {
    await assertFails(setDoc(doc(db('new1'), 'users', 'new1'),
      { name: 'Nia', role: 'admin', photoUrl: null, createdAt: serverTimestamp() }));
  });

  it('cannot add extra fields to a profile', async () => {
    await assertFails(setDoc(doc(db('new1'), 'users', 'new1'),
      { name: 'Nia', role: 'buyer', photoUrl: null, createdAt: serverTimestamp(), isAdmin: true }));
  });

  it('can change own name', async () => {
    await assertSucceeds(updateDoc(doc(db(BUYER), 'users', BUYER), { name: 'Bobby' }));
  });

  it('buyer cannot switch to seller', async () => {
    await assertFails(updateDoc(doc(db(BUYER), 'users', BUYER), { role: 'seller' }));
  });

  it('cannot edit someone else\'s profile', async () => {
    await assertFails(updateDoc(doc(db(BUYER), 'users', SELLER), { name: 'Hacked' }));
  });

  it('email and phone are only visible to the owner', async () => {
    await assertSucceeds(getDoc(doc(db(SELLER), 'users', SELLER, 'private', 'contact')));
    await assertFails(getDoc(doc(db(BUYER), 'users', SELLER, 'private', 'contact')));
  });
});

describe('saved homes and blocking', () => {
  it('can save a home for yourself', async () => {
    await assertSucceeds(setDoc(doc(db(BUYER), 'users', BUYER, 'saved', 'pub'), { savedAt: serverTimestamp() }));
  });

  it('cannot save into someone else\'s list', async () => {
    await assertFails(setDoc(doc(db(BUYER), 'users', SELLER, 'saved', 'pub'), { savedAt: serverTimestamp() }));
  });

  it('cannot read someone else\'s saved homes', async () => {
    await assertFails(getDocs(collection(db(BUYER), 'users', SELLER, 'saved')));
  });

  it('cannot block yourself', async () => {
    await assertFails(setDoc(doc(db(BUYER), 'users', BUYER, 'blocked', BUYER), { blockedAt: serverTimestamp() }));
  });
});

describe('listings', () => {
  it('seller can create a listing', async () => {
    await assertSucceeds(setDoc(doc(db(SELLER), 'listings', 'new'), listing()));
  });

  it('buyer cannot create a listing', async () => {
    await assertFails(setDoc(doc(db(BUYER), 'listings', 'new'), listing({ sellerId: BUYER })));
  });

  it('seller cannot create a listing under another seller', async () => {
    await assertFails(setDoc(doc(db(SELLER2), 'listings', 'new'), listing({ sellerId: SELLER })));
  });

  it('listing can be saved without sqft, year, lot size, or location', async () => {
    await assertSucceeds(setDoc(doc(db(SELLER), 'listings', 'new'),
      listing({ sqft: null, yearBuilt: null, lotSize: null, location: null })));
  });

  it('rejects a bad price, ZIP, or too many photos', async () => {
    await assertFails(setDoc(doc(db(SELLER), 'listings', 'a'), listing({ price: 0 })));
    await assertFails(setDoc(doc(db(SELLER), 'listings', 'b'), listing({ zip: '3030' })));
    await assertFails(setDoc(doc(db(SELLER), 'listings', 'c'), listing({ photos: new Array(13).fill('x') })));
  });

  it('rejects a listing with a missing field', async () => {
    const data = listing();
    delete data.sqft;
    await assertFails(setDoc(doc(db(SELLER), 'listings', 'new'), data));
  });

  it('buyer can read a published listing but not a draft', async () => {
    await assertSucceeds(getDoc(doc(db(BUYER), 'listings', 'pub')));
    await assertFails(getDoc(doc(db(BUYER), 'listings', 'draft')));
  });

  it('seller can read their own draft', async () => {
    await assertSucceeds(getDoc(doc(db(SELLER), 'listings', 'draft')));
  });

  it('buyer browse query must ask for published only', async () => {
    const listings = collection(db(BUYER), 'listings');
    await assertSucceeds(getDocs(query(listings, where('status', '==', 'published'))));
    await assertFails(getDocs(listings));
  });

  it('owner can edit and archive a listing', async () => {
    await assertSucceeds(updateDoc(doc(db(SELLER), 'listings', 'pub'),
      { price: 240000, updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(db(SELLER), 'listings', 'pub'),
      { status: 'archived', updatedAt: serverTimestamp() }));
  });

  it('another seller cannot edit the listing', async () => {
    await assertFails(updateDoc(doc(db(SELLER2), 'listings', 'pub'),
      { price: 1, updatedAt: serverTimestamp() }));
  });

  it('owner cannot give the listing to someone else', async () => {
    await assertFails(updateDoc(doc(db(SELLER), 'listings', 'pub'),
      { sellerId: SELLER2, updatedAt: serverTimestamp() }));
  });

  it('nobody can delete a listing', async () => {
    await assertFails(deleteDoc(doc(db(SELLER), 'listings', 'pub')));
  });
});

describe('viewing slots', () => {
  const slot = (start, end) => ({ start, end, status: 'open' });

  it('seller can add a future slot', async () => {
    await assertSucceeds(setDoc(doc(db(SELLER), 'listings', 'pub', 'slots', 'x'), slot(inDays(2), inDays(3))));
  });

  it('cannot add a slot in the past or ending before it starts', async () => {
    await assertFails(setDoc(doc(db(SELLER), 'listings', 'pub', 'slots', 'x'), slot(past, inDays(1))));
    await assertFails(setDoc(doc(db(SELLER), 'listings', 'pub', 'slots', 'y'), slot(inDays(3), inDays(2))));
  });

  it('buyer cannot add slots', async () => {
    await assertFails(setDoc(doc(db(BUYER), 'listings', 'pub', 'slots', 'x'), slot(inDays(2), inDays(3))));
  });

  it('buyer cannot book a slot directly', async () => {
    await seed((s) => setDoc(doc(s, 'listings', 'pub', 'slots', 'x'), slot(inDays(2), inDays(3))));
    await assertFails(updateDoc(doc(db(BUYER), 'listings', 'pub', 'slots', 'x'), { status: 'booked' }));
  });

  it('seller can remove an open slot but not a booked one', async () => {
    await seed(async (s) => {
      await setDoc(doc(s, 'listings', 'pub', 'slots', 'open'), slot(inDays(2), inDays(3)));
      await setDoc(doc(s, 'listings', 'pub', 'slots', 'booked'), { ...slot(inDays(2), inDays(3)), status: 'booked' });
    });
    await assertSucceeds(deleteDoc(doc(db(SELLER), 'listings', 'pub', 'slots', 'open')));
    await assertFails(deleteDoc(doc(db(SELLER), 'listings', 'pub', 'slots', 'booked')));
  });
});

describe('viewings', () => {
  beforeEach(async () => {
    await seed((s) => setDoc(doc(s, 'viewings', 'v1'), {
      listingId: 'pub', slotId: 'x', buyerId: BUYER, sellerId: SELLER,
      status: 'requested', createdAt: past, updatedAt: past,
    }));
  });

  const setStatus = (uid, status) =>
    updateDoc(doc(db(uid), 'viewings', 'v1'), { status, updatedAt: serverTimestamp() });

  it('the app cannot create a viewing (only the Cloud Function can)', async () => {
    await assertFails(setDoc(doc(db(BUYER), 'viewings', 'v2'), {
      listingId: 'pub', slotId: 'x', buyerId: BUYER, sellerId: SELLER,
      status: 'requested', createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
  });

  it('only the buyer and seller can see it', async () => {
    await assertSucceeds(getDoc(doc(db(BUYER), 'viewings', 'v1')));
    await assertSucceeds(getDoc(doc(db(SELLER), 'viewings', 'v1')));
    await assertFails(getDoc(doc(db(SELLER2), 'viewings', 'v1')));
  });

  it('seller can confirm a request', async () => {
    await assertSucceeds(setStatus(SELLER, 'confirmed'));
  });

  it('buyer cannot confirm their own request', async () => {
    await assertFails(setStatus(BUYER, 'confirmed'));
  });

  it('buyer can cancel', async () => {
    await assertSucceeds(setStatus(BUYER, 'cancelled'));
  });

  it('cannot change other fields like the time slot', async () => {
    await assertFails(updateDoc(doc(db(SELLER), 'viewings', 'v1'),
      { slotId: 'other', updatedAt: serverTimestamp() }));
  });
});

describe('chat', () => {
  const threadId = `pub_${BUYER}`;
  const newThread = (overrides = {}) => ({
    listingId: 'pub', listingTitle: 'Nice 3 bed house', buyerId: BUYER, sellerId: SELLER,
    participants: [BUYER, SELLER], createdAt: serverTimestamp(), lastMessageAt: serverTimestamp(),
    ...overrides,
  });
  const message = (senderId, text = 'Is it still for sale?') =>
    ({ senderId, text, createdAt: serverTimestamp() });

  async function seedThread() {
    await seed((s) => setDoc(doc(s, 'threads', threadId),
      { ...newThread(), createdAt: past, lastMessageAt: past }));
  }

  it('buyer can start a chat on a published listing', async () => {
    await assertSucceeds(setDoc(doc(db(BUYER), 'threads', threadId), newThread()));
  });

  it('cannot start a chat on a draft listing', async () => {
    await assertFails(setDoc(doc(db(BUYER), 'threads', `draft_${BUYER}`), newThread({ listingId: 'draft' })));
  });

  it('thread ID must be listing + buyer', async () => {
    await assertFails(setDoc(doc(db(BUYER), 'threads', 'random'), newThread()));
  });

  it('cannot pull in the wrong seller', async () => {
    await assertFails(setDoc(doc(db(BUYER), 'threads', threadId),
      newThread({ sellerId: SELLER2, participants: [BUYER, SELLER2] })));
  });

  it('people outside the chat cannot read it or its messages', async () => {
    await seedThread();
    await assertSucceeds(getDoc(doc(db(SELLER), 'threads', threadId)));
    await assertFails(getDoc(doc(db(SELLER2), 'threads', threadId)));
    await assertFails(getDocs(collection(db(SELLER2), 'threads', threadId, 'messages')));
  });

  it('people in the chat can send messages', async () => {
    await seedThread();
    await assertSucceeds(setDoc(doc(db(BUYER), 'threads', threadId, 'messages', 'm1'), message(BUYER)));
    await assertSucceeds(setDoc(doc(db(SELLER), 'threads', threadId, 'messages', 'm2'), message(SELLER, 'Yes it is')));
  });

  it('cannot send as someone else, or from outside the chat', async () => {
    await seedThread();
    await assertFails(setDoc(doc(db(BUYER), 'threads', threadId, 'messages', 'm1'), message(SELLER)));
    await assertFails(setDoc(doc(db(SELLER2), 'threads', threadId, 'messages', 'm1'), message(SELLER2)));
  });

  it('empty or very long messages are rejected', async () => {
    await seedThread();
    await assertFails(setDoc(doc(db(BUYER), 'threads', threadId, 'messages', 'm1'), message(BUYER, '')));
    await assertFails(setDoc(doc(db(BUYER), 'threads', threadId, 'messages', 'm2'), message(BUYER, 'a'.repeat(2001))));
  });

  it('a blocked buyer cannot send', async () => {
    await seedThread();
    await seed((s) => setDoc(doc(s, 'users', SELLER, 'blocked', BUYER), { blockedAt: past }));
    await assertFails(setDoc(doc(db(BUYER), 'threads', threadId, 'messages', 'm1'), message(BUYER)));
  });

  it('messages cannot be edited or deleted', async () => {
    await seedThread();
    await seed((s) => setDoc(doc(s, 'threads', threadId, 'messages', 'm1'),
      { senderId: BUYER, text: 'hi', createdAt: past }));
    await assertFails(updateDoc(doc(db(BUYER), 'threads', threadId, 'messages', 'm1'), { text: 'edited' }));
    await assertFails(deleteDoc(doc(db(BUYER), 'threads', threadId, 'messages', 'm1')));
  });

  it('can mark the chat read for yourself only', async () => {
    await seedThread();
    await assertSucceeds(updateDoc(doc(db(BUYER), 'threads', threadId), { [`lastReadAt.${BUYER}`]: serverTimestamp() }));
    await assertFails(updateDoc(doc(db(BUYER), 'threads', threadId), { [`lastReadAt.${SELLER}`]: serverTimestamp() }));
  });

  it('cannot fake the last message preview', async () => {
    await seedThread();
    await assertFails(updateDoc(doc(db(BUYER), 'threads', threadId), { lastMessage: 'fake' }));
  });
});
