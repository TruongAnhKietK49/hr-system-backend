import app from './app.js';
import { env } from './config/environment.js';
import { connectDB } from './config/database.js';

const startServer = async () => {
  try {
    await connectDB();
    app.listen(env.port, () => {
      console.log(`Server running! Access on http://localhost:${env.port}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error.message);
    process.exit(1);
  }
};

startServer();
