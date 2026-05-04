import jwt from 'jsonwebtoken';
import { env } from '../config/environment.js';

export const signAccessToken = (payload) => jwt.sign(payload, env.jwtSecret, { expiresIn: env.jwtExpiresIn });
export const signRefreshToken = (payload) => jwt.sign(payload, env.jwtRefreshSecret, { expiresIn: env.jwtRefreshExpiresIn });
export const verifyAccessToken = (token) => jwt.verify(token, env.jwtSecret);
export const verifyRefreshToken = (token) => jwt.verify(token, env.jwtRefreshSecret);
