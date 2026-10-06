# Circl

Circl helps people nearby discover others with shared AI/ML interests and compatible goals, then connect around projects.

## Features

- Nearby people discovery with live location updates and interest matching
- Connection requests and accepted connections
- Build, Learn, Mentor, and Hire preference matching
- One-to-one project pitches and manual Google Meet link sharing
- Personal project dashboard with optional public GitHub push feeds
- Dark and light themes

## Tech stack

- Flutter frontend in `lib/`
- Node.js, Express, Socket.IO, and MongoDB backend in `backend/`

## Run the backend

1. Install Node.js and make a local environment file:

   ```powershell
   cd backend
   Copy-Item .env.example .env
   ```

2. Set `MONGO_URI` to your MongoDB connection string and replace `JWT_SECRET` with a long, random value in `backend/.env`.
3. Install dependencies and start the server:

   ```powershell
   npm install
   npm run dev
   ```

The API listens on port `5000` by default. Do not commit `.env` or put real credentials in `.env.example`.

## Run the Flutter app

From the project root:

```powershell
flutter pub get
flutter run
```

Web builds use the same origin as the backend, which also serves `build/web` when present. Android emulators default to `http://10.0.2.2:5000`; other native targets default to `http://localhost:5000`. Override the backend origin when needed:

```powershell
flutter run --dart-define=BACKEND_ORIGIN=http://your-host:5000
```

For a web demo, build the frontend and then start the backend:

```powershell
flutter build web
cd backend
npm start
```

Open `http://localhost:5000` to use the app. A public demo also needs a reachable MongoDB instance and a deployment/tunnel that serves the backend and web build on the same origin.
