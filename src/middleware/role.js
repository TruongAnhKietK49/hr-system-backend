import { StatusCodes } from 'http-status-codes';
import { AppError } from '../utils/AppError.js';

export const restrictTo = (...roles) => (req, res, next) => {
  if (!req.user || !roles.includes(req.user.role)) {
    return next(new AppError('Forbidden', StatusCodes.FORBIDDEN));
  }
  return next();
};
