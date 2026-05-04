import { ROLES } from '../../constants/roles.js';
import { AppError } from '../../utils/AppError.js';
import { financeRepository } from './finance.repository.js';
import { presentSalaryList, presentSalaryRecord } from '../salary/salary.rbac.js';

class FinanceService {
  async getPayroll(user) {
    if (![ROLES.FINANCE_STAFF, ROLES.DIRECTOR].includes(user.role)) {
      throw new AppError('Forbidden', 403);
    }

    const payroll = await financeRepository.findPayroll({
      role: user.role,
      employeeId: user.employeeId
    });

    return presentSalaryList(user.role, payroll);
  }

  async getPayrollById(user, employeeId) {
    if (![ROLES.FINANCE_STAFF, ROLES.DIRECTOR].includes(user.role)) {
      throw new AppError('Forbidden', 403);
    }

    const payroll = await financeRepository.findPayrollByEmployeeId({
      role: user.role,
      employeeId: user.employeeId,
      targetEmployeeId: employeeId
    });

    if (!payroll) {
      throw new AppError('Payroll not found', 404);
    }

    return presentSalaryRecord(user.role, payroll);
  }
}

export const financeService = new FinanceService();
