// Storage security rules tests. Run from this folder with: npm test
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { ref, uploadBytes, getBytes } = require('firebase/storage');

let env;

const storage = (uid) => (uid ? env.authenticatedContext(uid).storage() : env.unauthenticatedContext().storage());
const smallImage = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3, 4]);
const jpeg = { contentType: 'image/jpeg' };

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-housebusiness',
    storage: { rules: fs.readFileSync(path.join(__dirname, '..', 'storage.rules'), 'utf8') },
  });
});

after(async () => {
  await env.cleanup();
});

describe('storage', () => {
  it('seller can upload a photo to their own listing folder', async () => {
    await assertSucceeds(uploadBytes(ref(storage('s1'), 'listing_photos/s1/l1/a.jpg'), smallImage, jpeg));
  });

  it('cannot upload into another seller\'s folder', async () => {
    await assertFails(uploadBytes(ref(storage('s2'), 'listing_photos/s1/l1/b.jpg'), smallImage, jpeg));
  });

  it('only images are allowed', async () => {
    await assertFails(uploadBytes(ref(storage('s1'), 'listing_photos/s1/l1/c.pdf'), smallImage,
      { contentType: 'application/pdf' }));
  });

  it('photos over 5 MB are rejected', async () => {
    const big = new Uint8Array(5 * 1024 * 1024 + 1);
    await assertFails(uploadBytes(ref(storage('s1'), 'listing_photos/s1/l1/big.jpg'), big, jpeg));
  });

  it('signed out people cannot see photos', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      uploadBytes(ref(ctx.storage(), 'listing_photos/s1/l1/d.jpg'), smallImage, jpeg));
    await assertSucceeds(getBytes(ref(storage('b1'), 'listing_photos/s1/l1/d.jpg')));
    await assertFails(getBytes(ref(storage(null), 'listing_photos/s1/l1/d.jpg')));
  });

  it('can only change your own profile photo', async () => {
    await assertSucceeds(uploadBytes(ref(storage('b1'), 'users/b1/profile.jpg'), smallImage, jpeg));
    await assertFails(uploadBytes(ref(storage('b1'), 'users/s1/profile.jpg'), smallImage, jpeg));
  });
});
