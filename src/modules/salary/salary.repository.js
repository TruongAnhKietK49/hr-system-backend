import { getPool } from '../../config/database.js';
import { addInput, SqlTypes } from '../../utils/procedure.js';
import {
  resolveSalaryDetailProcedure,
  resolveSalaryListProcedure,
  resolveSalaryUpdateProcedure
} from './salary.rbac.js';

class SalaryRepository {
  async findList(scope) {
    const pool = await getPool();
    const request = pool.request();
    addInput(request, 'RequesterEmployeeID', SqlTypes.VarChar, scope.requesterEmployeeId);
    const result = await request.execute(resolveSalaryListProcedure(scope.role));
    return result.recordset;
  }

  async findByEmployeeId(scope) {
    const pool = await getPool();
    const request = pool.request();
    addInput(request, 'RequesterEmployeeID', SqlTypes.VarChar, scope.requesterEmployeeId);
    addInput(request, 'TargetEmployeeID', SqlTypes.VarChar, scope.targetEmployeeId);
    const result = await request.execute(resolveSalaryDetailProcedure(scope.role));
    return result.recordset[0] || null;
  }

  async updateForDirector(payload) {
    const pool = await getPool();
    const request = pool.request();
    addInput(request, 'RequesterEmployeeID', SqlTypes.VarChar, payload.requesterEmployeeId);
    addInput(request, 'TargetEmployeeID', SqlTypes.VarChar, payload.targetEmployeeId);
    addInput(request, 'BaseSalary', SqlTypes.Decimal18_2, payload.baseSalary);
    addInput(request, 'SalaryCoefficient', SqlTypes.Decimal10_2, payload.salaryCoefficient);
    addInput(request, 'PositionCoefficient', SqlTypes.Decimal10_2, payload.positionCoefficient);
    addInput(request, 'Allowance', SqlTypes.Decimal18_2, payload.allowance);
    addInput(request, 'FormulaVersion', SqlTypes.NVarChar, payload.formulaVersion);
    const result = await request.execute(resolveSalaryUpdateProcedure(payload.role));
    return result.recordset[0] || null;
  }
}

export const salaryRepository = new SalaryRepository();
