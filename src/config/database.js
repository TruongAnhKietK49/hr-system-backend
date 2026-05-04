import sql from 'mssql';
import { env } from './environment.js';

let pool;

export const connectDB = async () => {
  if (pool) return pool;
  pool = await sql.connect(env.db);
  return pool;
};

export const getPool = async () => {
  if (!pool) {
    await connectDB();
  }
  return pool;
};

export { sql };
