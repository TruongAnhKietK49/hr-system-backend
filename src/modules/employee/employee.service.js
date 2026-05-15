import { ROLES } from "../../constants/roles.js";
import { ACTION_TYPES } from "../../constants/actionTypes.js";
import { AppError } from "../../utils/AppError.js";
import { employeeRepository } from "./employee.repository.js";
import { auditRepository } from "../audit/audit.repository.js";
import {
  presentEmployeeList,
  presentEmployeeRecord,
  sanitizeEmployeeUpdatePayload,
  sanitizeOwnProfileUpdatePayload,
} from "./employee.rbac.js";

class EmployeeService {
  async getAll(user) {
    const employees = await employeeRepository.findAllByRoleScope({
      role: user.role,
      employeeId: user.employeeId,
    });

    return presentEmployeeList(user.role, employees);
  }

  async getById(user, employeeId) {
    const isOwnProfile = user.employeeId === employeeId;

    if (isOwnProfile) {
      const record = await employeeRepository.getOwnProfile(
        user.employeeId,
        employeeId,
      );

      if (!record) {
        throw new AppError("Employee not found", 404);
      }

      return record;
    }

    const record = await employeeRepository.findByIdScoped({
      role: user.role,
      requesterEmployeeId: user.employeeId,
      targetEmployeeId: employeeId,
    });

    if (!record) {
      throw new AppError("Employee not found", 404);
    }

    return presentEmployeeRecord(user.role, record);
  }

  async update(user, employeeId, payload) {
    const isOwnProfile = user.employeeId === employeeId;

    if (isOwnProfile) {
      const current = await this.getById(user, employeeId);
      const sanitizedPayload = sanitizeOwnProfileUpdatePayload(payload);

      const updated = await employeeRepository.updateOwnProfile({
        requesterEmployeeId: user.employeeId,
        targetEmployeeId: employeeId,
        ...sanitizedPayload,
      });

      if (!updated) {
        throw new AppError("Employee not found", 404);
      }

      const visibleUpdated = await this.getById(user, employeeId);

      await auditRepository.createLog({
        actorId: user.employeeId,
        actorRole: user.role,
        actionType: ACTION_TYPES.UPDATE_EMPLOYEE,
        tableName: "Employee",
        recordId: employeeId,
        oldValues: JSON.stringify(current),
        newValues: JSON.stringify(visibleUpdated),
      });

      return visibleUpdated;
    }

    if (![ROLES.HR_STAFF, ROLES.HR_MANAGER].includes(user.role)) {
      throw new AppError("Forbidden", 403);
    }

    const current = await this.getById(user, employeeId);
    const sanitizedPayload = sanitizeEmployeeUpdatePayload(user.role, payload);

    const updated = await employeeRepository.updateByRole({
      role: user.role,
      requesterEmployeeId: user.employeeId,
      targetEmployeeId: employeeId,
      ...sanitizedPayload,
    });

    if (!updated) {
      throw new AppError("Employee not found", 404);
    }

    const visibleUpdated = await this.getById(user, employeeId);

    await auditRepository.createLog({
      actorId: user.employeeId,
      actorRole: user.role,
      actionType: ACTION_TYPES.UPDATE_EMPLOYEE,
      tableName: "Employee",
      recordId: employeeId,
      oldValues: JSON.stringify(current),
      newValues: JSON.stringify(visibleUpdated),
    });

    return visibleUpdated;
  }
}

export const employeeService = new EmployeeService();
