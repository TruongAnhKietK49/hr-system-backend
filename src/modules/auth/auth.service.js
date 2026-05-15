import { StatusCodes } from "http-status-codes";
import { authRepository } from "./auth.repository.js";
import { auditRepository } from "../audit/audit.repository.js";
import { verifyPassword, generateHashAndSalt } from "../../utils/password.js";
import {
  signAccessToken,
  signRefreshToken,
  verifyRefreshToken,
} from "../../utils/jwt.js";
import { AppError } from "../../utils/AppError.js";
import { ACTION_TYPES } from "../../constants/actionTypes.js";

class AuthService {
  async login({ username, password }) {
    const account = await authRepository.findAccountByUsername(username);

    if (!account || !account.IsActive || account.AccountStatus !== "ACTIVE") {
      await auditRepository.createLog({
        actorId: null,
        actorRole: null,
        actionType: ACTION_TYPES.LOGIN_FAILED,
        tableName: "Account",
        recordId: username,
        oldValues: null,
        newValues: JSON.stringify({ username }),
      });
      throw new AppError("Invalid credentials", StatusCodes.UNAUTHORIZED);
    }

    const matched = await verifyPassword(password, account.PasswordHash);
    if (!matched) {
      await auditRepository.createLog({
        actorId: account.EmployeeID,
        actorRole: account.Role,
        actionType: ACTION_TYPES.LOGIN_FAILED,
        tableName: "Account",
        recordId: account.EmployeeID,
        oldValues: null,
        newValues: JSON.stringify({ username }),
      });
      throw new AppError("Invalid credentials", StatusCodes.UNAUTHORIZED);
    }

    const payload = {
      employeeId: account.EmployeeID,
      username: account.Username,
      role: account.Role,
      departmentId: account.DepartmentID,
    };

    await auditRepository.createLog({
      actorId: account.EmployeeID,
      actorRole: account.Role,
      actionType: ACTION_TYPES.LOGIN_SUCCESS,
      tableName: "Account",
      recordId: account.EmployeeID,
      oldValues: null,
      newValues: JSON.stringify({ username: account.Username }),
    });

    return {
      accessToken: signAccessToken(payload),
      refreshToken: signRefreshToken(payload),
      user: {
        employeeId: account.EmployeeID,
        username: account.Username,
        fullName: account.FullName,
        role: account.Role,
        departmentId: account.DepartmentID,
      },
    };
  }

  async refresh({ refreshToken }) {
    try {
      const decoded = verifyRefreshToken(refreshToken);

      const account = await authRepository.findAccountByUsername(
        decoded.username,
      );

      if (!account || !account.IsActive || account.AccountStatus !== "ACTIVE") {
        throw new AppError("Invalid refresh token", StatusCodes.UNAUTHORIZED);
      }

      const payload = {
        employeeId: account.EmployeeID,
        username: account.Username,
        role: account.Role,
        departmentId: account.DepartmentID,
      };

      return {
        accessToken: signAccessToken(payload),
        user: {
          employeeId: account.EmployeeID,
          username: account.Username,
          fullName: account.FullName,
          role: account.Role,
          departmentId: account.DepartmentID,
        },
      };
    } catch {
      throw new AppError("Invalid refresh token", StatusCodes.UNAUTHORIZED);
    }
  }

  async changePassword({
    employeeId,
    username,
    role,
    currentPassword,
    newPassword,
  }) {
    const account = await authRepository.findAccountByUsername(username);

    if (!account || !account.IsActive || account.AccountStatus !== "ACTIVE") {
      throw new AppError(
        "Account not found or inactive",
        StatusCodes.UNAUTHORIZED,
      );
    }

    if (account.EmployeeID !== employeeId) {
      throw new AppError("Unauthorized", StatusCodes.UNAUTHORIZED);
    }

    const matched = await verifyPassword(currentPassword, account.PasswordHash);

    if (!matched) {
      throw new AppError(
        "Current password is incorrect",
        StatusCodes.BAD_REQUEST,
      );
    }

    const isSamePassword = await verifyPassword(
      newPassword,
      account.PasswordHash,
    );

    if (isSamePassword) {
      throw new AppError(
        "New password must be different from current password",
        StatusCodes.BAD_REQUEST,
      );
    }

    const { hash, salt } = await generateHashAndSalt(newPassword);

    await authRepository.updatePasswordByEmployeeId({
      employeeId,
      passwordHash: hash,
      passwordSalt: salt,
    });

    await auditRepository.createLog({
      actorId: employeeId,
      actorRole: role,
      actionType: ACTION_TYPES.CHANGE_PASSWORD,
      tableName: "Account",
      recordId: employeeId,
      oldValues: null,
      newValues: JSON.stringify({
        username,
        changedAt: new Date().toISOString(),
      }),
    });

    return {
      employeeId,
      username,
    };
  }
}

export const authService = new AuthService();
