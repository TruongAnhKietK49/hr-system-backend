import { getPool } from "../../config/database.js";
import { addInput, SqlTypes } from "../../utils/procedure.js";

class ApprovalRepository {
  async findPendingRequests(requesterId) {
    const pool = await getPool();
    const request = pool.request();

    addInput(request, "RequesterID", SqlTypes.VarChar, requesterId);

    const result = await request.execute("sp_Approval_ListPending_ForDirector");
    return result.recordset;
  }

  async findRequestForDirector({ requesterId, requestId }) {
    const pool = await getPool();
    const request = pool.request();

    addInput(request, "RequesterID", SqlTypes.VarChar, requesterId);
    addInput(request, "RequestID", SqlTypes.Int, requestId);

    const result = await request.execute("sp_Approval_GetRequestForDirector");
    return result.recordset[0] || null;
  }

  async approveCreateEmployee(payload) {
    const pool = await getPool();
    const request = pool.request();

    addInput(request, "RequestID", SqlTypes.Int, payload.requestId);
    addInput(request, "ApproverID", SqlTypes.VarChar, payload.approverId);
    addInput(request, "BaseSalary", SqlTypes.Decimal18_2, payload.baseSalary);
    addInput(
      request,
      "SalaryCoefficient",
      SqlTypes.Decimal10_2,
      payload.salaryCoefficient,
    );
    addInput(
      request,
      "PositionCoefficient",
      SqlTypes.Decimal10_2,
      payload.positionCoefficient,
    );
    addInput(request, "Allowance", SqlTypes.Decimal18_2, payload.allowance);
    addInput(
      request,
      "FormulaVersion",
      SqlTypes.NVarChar,
      payload.formulaVersion,
    );
    addInput(
      request,
      "PasswordHash",
      SqlTypes.MaxNVarChar,
      payload.passwordHash,
    );
    addInput(
      request,
      "PasswordSalt",
      SqlTypes.MaxNVarChar,
      payload.passwordSalt,
    );

    const result = await request.execute("sp_Approval_ApproveCreateEmployee");

    return result.recordset[0] || null;
  }

  async approveUpdateEmployee(payload) {
    const pool = await getPool();
    const request = pool.request();

    addInput(request, "RequestID", SqlTypes.Int, payload.requestId);
    addInput(request, "ApproverID", SqlTypes.VarChar, payload.approverId);

    const result = await request.execute("sp_Approval_ApproveUpdateEmployee");
    return result.recordset[0] || null;
  }

  async approveDeleteEmployee(payload) {
    const pool = await getPool();
    const request = pool.request();

    addInput(request, "RequestID", SqlTypes.Int, payload.requestId);
    addInput(request, "ApproverID", SqlTypes.VarChar, payload.approverId);

    const result = await request.execute("sp_Approval_ApproveDeleteEmployee");
    return result.recordset[0] || null;
  }

  async rejectRequest(payload) {
    const pool = await getPool();
    const request = pool.request();

    addInput(request, "RequestID", SqlTypes.Int, payload.requestId);
    addInput(request, "ApproverID", SqlTypes.VarChar, payload.approverId);
    addInput(
      request,
      "RejectionReason",
      SqlTypes.MaxNVarChar,
      payload.rejectionReason,
    );

    await request.execute("sp_Approval_RejectRequest");
  }
}

export const approvalRepository = new ApprovalRepository();
