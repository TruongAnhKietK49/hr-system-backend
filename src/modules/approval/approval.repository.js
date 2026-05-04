import { getPool, sql } from '../../config/database.js';
import { addInput, SqlTypes } from '../../utils/procedure.js';

class ApprovalRepository {
  async findPendingRequests(requesterId) {
    const pool = await getPool();
    const request = pool.request();
    addInput(request, 'RequesterID', SqlTypes.VarChar, requesterId);
    const result = await request.execute('sp_Approval_ListPending_ForDirector');
    return result.recordset;
  }

  async findRequestForDirector({ requesterId, requestId }) {
    const pool = await getPool();
    const request = pool.request();
    addInput(request, 'RequesterID', SqlTypes.VarChar, requesterId);
    addInput(request, 'RequestID', SqlTypes.Int, requestId);
    const result = await request.execute('sp_Approval_GetRequestForDirector');
    return result.recordset[0] || null;
  }

  async approveRequest(payload) {
    const pool = await getPool();
    const transaction = new sql.Transaction(pool);
    await transaction.begin();

    try {
      const request = new sql.Request(transaction);
      addInput(request, 'RequestID', SqlTypes.Int, payload.requestId);
      addInput(request, 'ApproverID', SqlTypes.VarChar, payload.approverId);
      addInput(request, 'BaseSalary', SqlTypes.Decimal18_2, payload.baseSalary);
      addInput(request, 'SalaryCoefficient', SqlTypes.Decimal10_2, payload.salaryCoefficient);
      addInput(request, 'PositionCoefficient', SqlTypes.Decimal10_2, payload.positionCoefficient);
      addInput(request, 'Allowance', SqlTypes.Decimal18_2, payload.allowance);
      addInput(request, 'FormulaVersion', SqlTypes.NVarChar, payload.formulaVersion);
      addInput(request, 'PasswordHash', SqlTypes.MaxNVarChar, payload.passwordHash);
      addInput(request, 'PasswordSalt', SqlTypes.MaxNVarChar, payload.passwordSalt);
      const result = await request.execute('sp_Approval_ApproveCreateEmployee');
      await transaction.commit();
      return result.recordset[0] || null;
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  }

  async rejectRequest(payload) {
    const pool = await getPool();
    const request = pool.request();
    addInput(request, 'RequestID', SqlTypes.Int, payload.requestId);
    addInput(request, 'ApproverID', SqlTypes.VarChar, payload.approverId);
    addInput(request, 'RejectionReason', SqlTypes.MaxNVarChar, payload.rejectionReason);
    await request.execute('sp_Approval_RejectRequest');
  }
}

export const approvalRepository = new ApprovalRepository();
