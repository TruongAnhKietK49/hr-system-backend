import { authService } from './auth.service.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { success } from '../../utils/apiResponse.js';
import { validate, loginSchema, refreshSchema } from '../../validations/schemas.js';

export const login = asyncHandler(async (req, res) => {
  const payload = validate(loginSchema, req.body);
  const data = await authService.login(payload);
  return success(res, data, 'Login successful');
});

export const refresh = asyncHandler(async (req, res) => {
  const payload = validate(refreshSchema, req.body);
  const data = await authService.refresh(payload);
  return success(res, data, 'Token refreshed');
});
