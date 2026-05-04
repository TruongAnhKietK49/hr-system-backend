import { salaryRepository } from '../salary/salary.repository.js';

class FinanceRepository {
  async findPayroll(scope) {
    return salaryRepository.findList({
      role: scope.role,
      requesterEmployeeId: scope.employeeId
    });
  }

  async findPayrollByEmployeeId(scope) {
    return salaryRepository.findByEmployeeId({
      role: scope.role,
      requesterEmployeeId: scope.employeeId,
      targetEmployeeId: scope.targetEmployeeId
    });
  }
}

export const financeRepository = new FinanceRepository();
