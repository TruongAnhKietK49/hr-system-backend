import { authService } from "./auth.service.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { success } from "../../utils/apiResponse.js";
import {
  validate,
  loginSchema,
  refreshSchema,
  changePasswordSchema,
} from "../../validations/schemas.js";

export const login = asyncHandler(async (req, res) => {
  const payload = validate(loginSchema, req.body);
  const data = await authService.login(payload);
  return success(res, data, "Login successful");
});

export const refresh = asyncHandler(async (req, res) => {
  const payload = validate(refreshSchema, req.body);
  const data = await authService.refresh(payload);
  return success(res, data, "Token refreshed");
});

export const changePassword = asyncHandler(async (req, res) => {
  const payload = validate(changePasswordSchema, req.body);

  const data = await authService.changePassword({
    employeeId: req.user.employeeId,
    username: req.user.username,
    role: req.user.role,
    currentPassword: payload.currentPassword,
    newPassword: payload.newPassword,
  });

  return success(res, data, "Password changed successfully");
});
