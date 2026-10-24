// backend/scripts/seedDemoUsers.js
// Creates (or refreshes) a set of demo students around a location so the
// nearby feed and 3D constellation have people in them during a demo.
//
//   node scripts/seedDemoUsers.js                 -> around the most recently located real user
//   node scripts/seedDemoUsers.js 11.02 76.96     -> around this latitude/longitude
//   node scripts/seedDemoUsers.js --remove        -> delete all demo users (and their connections/pitches)
//
// Every demo account uses an @circl.test email and the password below. Re-running
// is safe: existing demo users are updated in place and re-scattered around the anchor,
// and their activity (connections, pitches, projects) *among each other* is reset to
// the script below. Anything between a demo account and a real account is left alone.
//
// Each account ends up with accepted connections, incoming + outgoing pending requests,
// pitches in every state (waiting, accepted, declined, matched both ways) and at least one
// project with members and a linked repo. Repos are real public GitHub repos, because the
// dashboard's commit feed reads live commits from GitHub's public API.
require('dotenv').config();

const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const User = require('../models/User');
const Connection = require('../models/Connection');
const Pitch = require('../models/Pitch');
const Project = require('../models/Project');

const DEMO_DOMAIN = '@circl.test';
const DEMO_PASSWORD = 'circl123';

const DEMO_USERS = [
  ['Arjun K', 21, ['Gen AI', 'RAG', 'MLOps'], 'Hire', '#00E676', 'Leading a campus team shipping a RAG tutor for first-years. Looking for one more builder.'],
  ['Sneha R', 20, ['RAG', 'Agentic AI', 'LangChain'], 'Build', '#FFD740', 'Prototyping an agent that files lab reports from voice notes.'],
  ['Priya S', 22, ['Agentic AI', 'Gen AI', 'MLOps'], 'Build', '#40C4FF', 'Final-year IT. Wants to deploy an LLM agent end to end, not just a notebook.'],
  ['Aarav M', 21, ['LLM', 'RAG', 'LangChain'], 'Build', '#E040FB', 'Building a document Q&A bot over the college syllabus PDFs.'],
  ['Diya P', 23, ['Gen AI', 'LLM', 'Agentic AI'], 'Hire', '#FF6E40', 'Startup intern recruiting two students for a paid Gen AI side project.'],
  ['Meera V', 20, ['MLOps', 'Cloud/DevOps', 'Data Engineering'], 'Build', '#69F0AE', 'Loves pipelines. Has a free-tier GPU setup and wants a model to serve.'],
  ['Harish T', 24, ['Machine Learning', 'MLOps'], 'Mentor', '#448AFF', 'PG student. Happy to review your training and deployment setup.'],
  ['Ananya J', 19, ['SLM', 'LLM', 'Gen AI'], 'Learn', '#FF5252', 'Second-year. Wants a study buddy for fine-tuning small models.'],
  ['Vikram N', 22, ['Data Engineering', 'Cloud/DevOps'], 'Hire', '#FFD740', 'Hiring a data intern for a college analytics dashboard.'],
  ['Rohan D', 23, ['Machine Learning', 'Deep Learning', 'Computer Vision'], 'Mentor', '#E040FB', 'Kaggle regular. Mentors juniors on vision models.'],
  ['Nikhil G', 20, ['Deep Learning', 'SLM'], 'Learn', '#40C4FF', 'Working through a deep learning course and wants accountability.'],
  ['Lakshmi B', 21, ['Computer Vision', 'Data Engineering'], 'Mentor', '#69F0AE', 'Built a crop-disease detector. Can guide anyone starting with CV.'],
  ['Karthik S', 20, ['Computer Vision', 'Deep Learning'], 'Learn', '#FF5252', 'Curious about vision transformers, looking for people to learn with.']
];

const emailFor = (name) => `${name.split(' ')[0].toLowerCase()}${DEMO_DOMAIN}`;

// Activity between demo accounts, by first name. Pairs are [sender, receiver].
const ACCEPTED = [
  ['arjun', 'priya'], ['arjun', 'sneha'], ['meera', 'arjun'], ['arjun', 'harish'],
  ['priya', 'aarav'], ['diya', 'priya'], ['sneha', 'aarav'], ['ananya', 'nikhil'],
  ['harish', 'ananya'], ['rohan', 'karthik'], ['lakshmi', 'rohan'], ['karthik', 'nikhil'],
  ['vikram', 'meera'], ['aarav', 'diya'], ['vikram', 'lakshmi'], ['harish', 'meera']
];
// Every account has at least one request waiting on them and one they're waiting on.
const PENDING = [
  ['diya', 'arjun'], ['karthik', 'arjun'], ['arjun', 'rohan'], ['nikhil', 'priya'],
  ['priya', 'harish'], ['meera', 'sneha'], ['sneha', 'vikram'], ['aarav', 'harish'],
  ['vikram', 'aarav'], ['diya', 'vikram'], ['rohan', 'diya'], ['lakshmi', 'meera'],
  ['ananya', 'rohan'], ['karthik', 'ananya'], ['vikram', 'ananya'], ['harish', 'vikram'],
  ['rohan', 'nikhil'], ['nikhil', 'lakshmi'], ['lakshmi', 'karthik']
];
const REJECTED = [['sneha', 'rohan']];

// [from, to, status, text] — only between accepted connections, one per direction.
// arjun↔priya, rohan↔karthik, ananya↔nikhil and vikram↔meera are matched (both accepted),
// which unlocks the Meet handoff on their pitch screens.
const PITCHES = [
  ['arjun', 'priya', 'accepted', 'Let\'s build a RAG tutor for first-years: you own the agent that plans study sessions, I\'ll handle retrieval over the syllabus.'],
  ['priya', 'arjun', 'accepted', 'Pair on a placement-prep assistant? It answers from seniors\' interview notes and tracks what you still need to practise.'],
  ['rohan', 'karthik', 'accepted', 'I can mentor you through training a small vision transformer on the campus plant dataset. One session a week.'],
  ['karthik', 'rohan', 'accepted', 'Would you review my ViT experiments every Friday? I\'ll write up what I learn for the juniors.'],
  ['ananya', 'nikhil', 'accepted', 'Study group: fine-tune a small language model together, one chapter of the course per week.'],
  ['nikhil', 'ananya', 'accepted', 'Let\'s rebuild micrograd from scratch first, then move on to fine-tuning. Keeps us honest about the maths.'],
  ['vikram', 'meera', 'accepted', 'Paid internship: help me ship the college analytics dashboard. You set up the data pipelines, I\'ll do the frontend.'],
  ['meera', 'vikram', 'accepted', 'In! Can we deploy it with a proper CI pipeline so updates go out without anyone touching the server?'],
  ['sneha', 'arjun', 'pending', 'Join my voice lab-report agent? It transcribes what you say during a lab and drafts the report for you.'],
  ['arjun', 'meera', 'pending', 'Could you set up model serving for the RAG tutor? We need it to stay up through demo day.'],
  ['harish', 'ananya', 'pending', 'Happy to mentor your fine-tuning project. Send me your training script and we\'ll go through it.'],
  ['aarav', 'priya', 'pending', 'Want to add your agent to my syllabus Q&A bot? Students could ask it to plan revision, not just answer questions.'],
  ['diya', 'aarav', 'pending', 'We\'re hiring for a paid Gen AI side project: a support chatbot for a local startup. Interested?'],
  ['lakshmi', 'rohan', 'pending', 'Co-mentor the CV beginners\' track with me? You take model training, I\'ll take data collection.'],
  ['karthik', 'nikhil', 'pending', 'Let\'s compare CNNs and ViTs on the same dataset and present it at the department seminar.'],
  ['vikram', 'lakshmi', 'pending', 'Your crop-disease detector would make a great dashboard module. Want to plug it in?'],
  ['aarav', 'sneha', 'accepted', 'Let\'s merge our bots: your agent files the lab report, mine answers questions about it.'],
  ['priya', 'diya', 'rejected', 'Could your startup sponsor our agents hackathon team?'],
  ['meera', 'harish', 'rejected', 'Would you co-author a blog post on deploying ML models on free tiers?']
];

// [owner, name, members, repo] — members must be the owner's accepted connections.
const PROJECTS = [
  ['arjun', 'RAG Tutor', ['priya', 'sneha'], 'https://github.com/run-llama/llama_index'],
  ['arjun', 'Campus Help Desk Agent', ['meera', 'harish'], 'https://github.com/microsoft/autogen'],
  ['priya', 'Placement Prep Assistant', ['arjun', 'aarav'], 'https://github.com/langchain-ai/langchain'],
  ['sneha', 'Voice Lab-Report Agent', ['arjun', 'aarav'], 'https://github.com/openai/whisper'],
  ['aarav', 'Syllabus Q&A Bot', ['priya', 'sneha', 'diya'], 'https://github.com/octocat/Hello-World'],
  ['diya', 'Startup Support Chatbot', ['priya', 'aarav'], 'https://github.com/octocat/Spoon-Knife'],
  ['meera', 'Model Serving Pipeline', ['vikram', 'arjun'], 'https://github.com/mlflow/mlflow'],
  ['harish', 'Mentoring Circle', ['ananya', 'arjun', 'meera'], null],
  ['ananya', 'SLM Fine-tuning Study', ['nikhil', 'harish'], 'https://github.com/karpathy/nanoGPT'],
  ['vikram', 'College Analytics Dashboard', ['meera', 'lakshmi'], 'https://github.com/apache/airflow'],
  ['rohan', 'Vision Mentoring Track', ['karthik', 'lakshmi'], 'https://github.com/ultralytics/ultralytics'],
  ['nikhil', 'Deep Learning From Scratch', ['ananya', 'karthik'], 'https://github.com/karpathy/micrograd'],
  ['lakshmi', 'Crop Disease Detector', ['rohan', 'vikram'], 'https://github.com/ultralytics/ultralytics'],
  ['karthik', 'ViT Study Group', ['rohan', 'nikhil'], 'https://github.com/huggingface/transformers']
];

const hoursAgo = (h) => new Date(Date.now() - h * 3600 * 1000);

// Random point 0.2–4.5 km from the anchor (inside /nearby's 5 km radius).
function scatter(lat, lng) {
  const distanceKm = 0.2 + Math.random() * 4.3;
  const bearing = Math.random() * 2 * Math.PI;
  const dLat = (distanceKm / 111.32) * Math.cos(bearing);
  const dLng = (distanceKm / (111.32 * Math.cos((lat * Math.PI) / 180))) * Math.sin(bearing);
  return [lng + dLng, lat + dLat];
}

async function findAnchor() {
  const [latArg, lngArg] = process.argv.slice(2).map(Number);
  if (Number.isFinite(latArg) && Number.isFinite(lngArg)) return { lat: latArg, lng: lngArg, label: 'command line' };

  const recent = await User.findOne({
    email: { $not: new RegExp(`${DEMO_DOMAIN.replace('.', '\\.')}$`) },
    lastLocationAt: { $ne: null }
  }).sort({ lastLocationAt: -1 });
  if (!recent) throw new Error('No located user found. Pass a latitude and longitude, e.g. node scripts/seedDemoUsers.js 11.02 76.96');
  const [lng, lat] = recent.location.coordinates;
  return { lat, lng, label: `${recent.name}'s last location` };
}

async function removeDemoUsers() {
  const demo = await User.find({ email: { $regex: `${DEMO_DOMAIN.replace('.', '\\.')}$` } }, '_id');
  const ids = demo.map((u) => u._id);
  await Connection.deleteMany({ $or: [{ senderId: { $in: ids } }, { receiverId: { $in: ids } }] });
  await Pitch.deleteMany({ $or: [{ fromUser: { $in: ids } }, { toUser: { $in: ids } }] });
  await User.deleteMany({ _id: { $in: ids } });
  console.log(`Removed ${ids.length} demo users and their connections/pitches.`);
}

async function seed() {
  const anchor = await findAnchor();
  const password = await bcrypt.hash(DEMO_PASSWORD, await bcrypt.genSalt(10));

  for (const [name, age, interests, preference, avatarColor, bio] of DEMO_USERS) {
    const email = emailFor(name);
    await User.findOneAndUpdate(
      { email },
      {
        name, email, password, age, interests, preference, avatarColor, bio,
        location: { type: 'Point', coordinates: scatter(anchor.lat, anchor.lng) },
        lastLocationAt: new Date()
      },
      { upsert: true, setDefaultsOnInsert: true }
    );
    console.log(`  ${email.padEnd(22)} ${preference.padEnd(7)} ${interests.join(', ')}`);
  }
  console.log(`\nSeeded ${DEMO_USERS.length} demo users around ${anchor.label} (${anchor.lat.toFixed(4)}, ${anchor.lng.toFixed(4)}).`);
  await seedActivity();
  console.log(`Password for every demo account: ${DEMO_PASSWORD}`);
}

async function seedActivity() {
  const demo = await User.find({ email: { $regex: `${DEMO_DOMAIN.replace('.', '\\.')}$` } });
  const id = Object.fromEntries(demo.map((u) => [u.email.split('@')[0], u._id]));
  const ids = demo.map((u) => u._id);

  // Reset only activity where every party is a demo account.
  await Connection.deleteMany({ senderId: { $in: ids }, receiverId: { $in: ids } });
  await Pitch.deleteMany({ fromUser: { $in: ids }, toUser: { $in: ids } });
  await Project.deleteMany({ owner: { $in: ids } });

  const accepted = new Set(ACCEPTED.map(([a, b]) => [a, b].sort().join('|')));
  const connection = (status) => ([from, to], i) => ({
    senderId: id[from], receiverId: id[to], status, createdAt: hoursAgo(2 + i * 5)
  });
  await Connection.insertMany([
    ...ACCEPTED.map(connection('accepted')),
    ...PENDING.map(connection('pending')),
    ...REJECTED.map(connection('rejected'))
  ]);

  await Pitch.insertMany(PITCHES.map(([from, to, status, text], i) => {
    if (!accepted.has([from, to].sort().join('|'))) throw new Error(`Pitch ${from}→${to} needs an accepted connection`);
    return { fromUser: id[from], toUser: id[to], status, text, createdAt: hoursAgo(1 + i * 3) };
  }));

  await Project.insertMany(PROJECTS.map(([owner, name, members, repoUrl], i) => {
    for (const m of members) {
      if (!accepted.has([owner, m].sort().join('|'))) throw new Error(`Project "${name}": ${m} isn't ${owner}'s accepted connection`);
    }
    return { owner: id[owner], name, memberIds: members.map((m) => id[m]), repoUrl, createdAt: hoursAgo(24 + i * 7) };
  }));

  const matched = PITCHES.filter(([from, to, status]) =>
    status === 'accepted' && PITCHES.some(([f, t, s]) => f === to && t === from && s === 'accepted')).length / 2;
  console.log(`Activity: ${ACCEPTED.length} connections, ${PENDING.length} pending requests, ${PITCHES.length} pitches (${matched} matched pairs), ${PROJECTS.length} projects.`);
}

mongoose
  .connect(process.env.MONGO_URI)
  .then(() => (process.argv.includes('--remove') ? removeDemoUsers() : seed()))
  .catch((err) => {
    console.error(err.message);
    process.exitCode = 1;
  })
  .finally(() => mongoose.disconnect());
