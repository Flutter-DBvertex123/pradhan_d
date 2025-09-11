const admin = require("firebase-admin");
const fs = require("fs");

// Initialize Firebase Admin
admin.initializeApp({
  projectId: "chunaw-a66df"   // 👈 you can use any fake id here
});
const db = admin.firestore();

// If you’re using emulator:
db.settings({
  host: "127.0.0.1:8080",
  ssl: false
});

// Load JSON file
const data = JSON.parse(fs.readFileSync("./functions/users.json", "utf8"));

async function seed() {
  for (const user of data) {
    const docId = user.id; // use "id" as Firestore document ID
    await db.collection("users").doc(docId).set(user);
    console.log(`✅ Created doc: users/${docId}`);
  }
  console.log("🌱 Seeding complete!");
}

seed().then(() => process.exit());
