import { getPool } from "../../config/database.js";
import { addInput, SqlTypes } from "../../utils/procedure.js";
import {
  resolveEmployeeDetailProcedure,
  resolveEmployeeListProcedure,
  resolveEmployeeUpdateProcedure,
} from "./employee.rbac.js";

class EmployeeRepository {
  async findAllByRoleScope(scope) {
    const pool = await getPool();
    const request = pool.request();
    addInput(
      request,
      "RequesterEmployeeID",
      SqlTypes.VarChar,
      scope.employeeId,
    );
    const result = await request.execute(
      resolveEmployeeListProcedure(scope.role),
    );
    return result.recordset;
  }

  async findByIdScoped(scope) {
    const pool = await getPool();
    const request = pool.request();
    addInput(
      request,
      "RequesterEmployeeID",
      SqlTypes.VarChar,
      scope.requesterEmployeeId,
    );
    addInput(
      request,
      "TargetEmployeeID",
      SqlTypes.VarChar,
      scope.targetEmployeeId,
    );
    const result = await request.execute(
      resolveEmployeeDetailProcedure(scope.role),
    );
    return result.recordset[0] || null;
  }

  async getOwnProfile(requesterEmployeeId, targetEmployeeId) {
    const pool = await getPool();
    const request = pool.request();

    addInput(
      request,
      "RequesterEmployeeID",
      SqlTypes.VarChar,
      requesterEmployeeId,
    );

    addInput(request, "TargetEmployeeID", SqlTypes.VarChar, targetEmployeeId);

    const result = await request.execute("sp_Employee_GetOwnProfile");
    return result.recordset[0] || null;
  }

  async updateByRole(payload) {
    const pool = await getPool();
    const request = pool.request();
    addInput(
      request,
      "RequesterEmployeeID",
      SqlTypes.VarChar,
      payload.requesterEmployeeId,
    );
    addInput(
      request,
      "TargetEmployeeID",
      SqlTypes.VarChar,
      payload.targetEmployeeId,
    );
    addInput(request, "FullName", SqlTypes.NVarChar, payload.fullName);
    addInput(request, "Gender", SqlTypes.NVarChar, payload.gender);
    addInput(request, "DateOfBirth", SqlTypes.Date, payload.dateOfBirth);
    addInput(request, "PhoneNumber", SqlTypes.VarChar, payload.phoneNumber);

    if (payload.role === "HR Manager") {
      addInput(request, "DepartmentID", SqlTypes.VarChar, payload.departmentId);
      addInput(request, "PositionID", SqlTypes.Int, payload.positionId);
      addInput(
        request,
        "EmploymentStatus",
        SqlTypes.NVarChar,
        payload.employmentStatus,
      );
      addInput(request, "IsActive", SqlTypes.Bit, payload.isActive);
    }

    const result = await request.execute(
      resolveEmployeeUpdateProcedure(payload.role),
    );
    return result.recordset[0] || null;
  }

  async updateOwnProfile(payload) {
    const pool = await getPool();
    const request = pool.request();

    addInput(
      request,
      "RequesterEmployeeID",
      SqlTypes.VarChar,
      payload.requesterEmployeeId,
    );
    addInput(
      request,
      "TargetEmployeeID",
      SqlTypes.VarChar,
      payload.targetEmployeeId,
    );
    addInput(request, "FullName", SqlTypes.NVarChar, payload.fullName);
    addInput(request, "Gender", SqlTypes.NVarChar, payload.gender);
    addInput(request, "DateOfBirth", SqlTypes.Date, payload.dateOfBirth);
    addInput(request, "PhoneNumber", SqlTypes.VarChar, payload.phoneNumber);

    const result = await request.execute("sp_Employee_UpdateOwnProfile");
    return result.recordset[0] || null;
  }
}

export const employeeRepository = new EmployeeRepository();
