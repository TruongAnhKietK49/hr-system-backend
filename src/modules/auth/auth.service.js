import { StatusCodes } from 'http-status-codes';
import { authRepository } from './auth.repository.js';
import { auditRepository } from '../audit/audit.repository.js';
import { verifyPassword } from '../../utils/password.js';
import { signAccessToken, signRefreshToken, verifyRefreshToken } from '../../utils/jwt.js';
import { AppError } from '../../utils/AppError.js';
import { ACTION_TYPES } from '../../constants/actionTypes.js';

class AuthService {
  async login({ username, password }) {
    const account = await authRepository.findAccountByUsername(username);

    if (!account || !account.IsActive || account.AccountStatus !== 'ACTIVE') {
      await auditRepository.createLog({
        actorId: null,
        actorRole: null,
        actionType: ACTION_TYPES.LOGIN_FAILED,
        tableName: 'Account',
        recordId: username,
        oldValues: null,
        newValues: JSON.stringify({ username })
      });
      throw new AppError('Invalid credentials', StatusCodes.UNAUTHORIZED);
    }

    const matched = await verifyPassword(password, account.PasswordHash);
    if (!matched) {
      await auditRepository.createLog({
        actorId: account.EmployeeID,
        actorRole: account.Role,
        actionType: ACTION_TYPES.LOGIN_FAILED,
        tableName: 'Account',
        recordId: account.EmployeeID,
        oldValues: null,
        newValues: JSON.stringify({ username })
      });
      throw new AppError('Invalid credentials', StatusCodes.UNAUTHORIZED);
    }

    const payload = {
      employeeId: account.EmployeeID,
      username: account.Username,
      role: account.Role,
      departmentId: account.DepartmentID
    };

    await auditRepository.createLog({
      actorId: account.EmployeeID,
      actorRole: account.Role,
      actionType: ACTION_TYPES.LOGIN_SUCCESS,
      tableName: 'Account',
      recordId: account.EmployeeID,
      oldValues: null,
      newValues: JSON.stringify({ username: account.Username })
    });

    return {
      accessToken: signAccessToken(payload),
      refreshToken: signRefreshToken(payload),
      user: {
        employeeId: account.EmployeeID,
        username: account.Username,
        fullName: account.FullName,
        role: account.Role,
        departmentId: account.DepartmentID
      }
    };
  }

  async refresh({ refreshToken }) {
    try {
      const decoded = verifyRefreshToken(refreshToken);
      return {
        accessToken: signAccessToken({
          employeeId: decoded.employeeId,
          username: decoded.username,
          role: decoded.role,
          departmentId: decoded.departmentId
        })
      };
    } catch {
      throw new AppError('Invalid refresh token', StatusCodes.UNAUTHORIZED);
    }
  }
}

export const authService = new AuthService();
