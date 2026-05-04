import { StatusCodes } from 'http-status-codes';
import { verifyAccessToken } from '../utils/jwt.js';
import { AppError } from '../utils/AppError.js';

export const protect = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(new AppError('Unauthorized', StatusCodes.UNAUTHORIZED));
  }

  const token = authHeader.split(' ')[1];

  try {
    req.user = verifyAccessToken(token);
    return next();
  } catch {
    return next(new AppError('Invalid or expired token', StatusCodes.UNAUTHORIZED));
  }
};
