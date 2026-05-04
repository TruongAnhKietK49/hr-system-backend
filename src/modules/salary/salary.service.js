import { ROLES } from '../../constants/roles.js';
import { AppError } from '../../utils/AppError.js';
import { presentSalaryList, presentSalaryRecord } from './salary.rbac.js';
import { salaryRepository } from './salary.repository.js';

class SalaryService {
  async getList(user) {
    if (![ROLES.FINANCE_STAFF, ROLES.DIRECTOR].includes(user.role)) {
      throw new AppError('Forbidden', 403);
    }

    const salaries = await salaryRepository.findList({
      role: user.role,
      requesterEmployeeId: user.employeeId
    });

    return presentSalaryList(user.role, salaries);
  }

  async getByEmployeeId(user, employeeId) {
    if (![ROLES.FINANCE_STAFF, ROLES.DIRECTOR].includes(user.role)) {
      throw new AppError('Forbidden', 403);
    }

    const salary = await salaryRepository.findByEmployeeId({
      role: user.role,
      requesterEmployeeId: user.employeeId,
      targetEmployeeId: employeeId
    });

    if (!salary) {
      throw new AppError('Salary not found', 404);
    }

    return presentSalaryRecord(user.role, salary);
  }

  async updateForDirector(user, employeeId, payload) {
    if (user.role !== ROLES.DIRECTOR) {
      throw new AppError('Only Director can update salary', 403);
    }

    const salary = await salaryRepository.updateForDirector({
      role: user.role,
      requesterEmployeeId: user.employeeId,
      targetEmployeeId: employeeId,
      ...payload
    });

    if (!salary) {
      throw new AppError('Salary not found', 404);
    }

    return presentSalaryRecord(user.role, salary);
  }
}

export const salaryService = new SalaryService();
