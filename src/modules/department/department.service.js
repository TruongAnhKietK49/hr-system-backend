import { ROLES } from "../../constants/roles.js";
import { ACTION_TYPES } from "../../constants/actionTypes.js";
import { AppError } from "../../utils/AppError.js";
import { departmentRepository } from "./department.repository.js";
import { auditRepository } from "../audit/audit.repository.js";

class DepartmentService {
  async getAll() {
    return departmentRepository.findAll();
  }

  async searchManagerCandidates(user, { keyword = "", limit = 20 }) {
    if (![ROLES.HR_MANAGER, ROLES.DIRECTOR].includes(user.role)) {
      throw new AppError("Forbidden", 403);
    }

    const safeLimit = Number.isFinite(Number(limit))
      ? Math.min(Math.max(Number(limit), 1), 50)
      : 20;

    return departmentRepository.searchManagerCandidates({
      keyword: keyword?.trim() || null,
      limit: safeLimit,
    });
  }

  async create(user, payload) {
    if (![ROLES.HR_MANAGER, ROLES.DIRECTOR].includes(user.role)) {
      throw new AppError("Forbidden", 403);
    }

    const department = await departmentRepository.create(payload);

    await auditRepository.createLog({
      actorId: user.employeeId,
      actorRole: user.role,
      actionType: ACTION_TYPES.CREATE_DEPARTMENT,
      tableName: "Department",
      recordId: department?.DepartmentID || payload.departmentId,
      oldValues: null,
      newValues: JSON.stringify(department || payload),
    });

    return department;
  }

  async update(user, id, payload) {
    if (![ROLES.HR_MANAGER, ROLES.DIRECTOR].includes(user.role)) {
      throw new AppError("Forbidden", 403);
    }

    const updated = await departmentRepository.updateById(id, payload);

    if (!updated) {
      throw new AppError("Department not found", 404);
    }

    await auditRepository.createLog({
      actorId: user.employeeId,
      actorRole: user.role,
      actionType: ACTION_TYPES.UPDATE_DEPARTMENT,
      tableName: "Department",
      recordId: id,
      oldValues: null,
      newValues: JSON.stringify(updated),
    });

    return updated;
  }

  async delete(user, id) {
    if (![ROLES.HR_MANAGER, ROLES.DIRECTOR].includes(user.role)) {
      throw new AppError("Forbidden", 403);
    }

    await departmentRepository.deleteById(id);

    await auditRepository.createLog({
      actorId: user.employeeId,
      actorRole: user.role,
      actionType: ACTION_TYPES.DELETE_DEPARTMENT,
      tableName: "Department",
      recordId: id,
      oldValues: null,
      newValues: null,
    });
  }
}

export const departmentService = new DepartmentService();
