import { getPool } from "../../config/database.js";
import { addInput, SqlTypes } from "../../utils/procedure.js";

class AuditRepository {
  async createLog(payload) {
    const pool = await getPool();
    const request = pool.request();

    addInput(request, "ActorID", SqlTypes.VarChar, payload.actorId ?? null);
    addInput(
      request,
      "ActorRole",
      SqlTypes.NVarChar,
      payload.actorRole ?? null,
    );
    addInput(
      request,
      "ActionType",
      SqlTypes.NVarChar,
      payload.actionType ?? null,
    );
    addInput(
      request,
      "TableName",
      SqlTypes.NVarChar,
      payload.tableName ?? null,
    );
    addInput(
      request,
      "RecordID",
      SqlTypes.VarChar,
      payload.recordId != null ? String(payload.recordId) : null,
    );
    addInput(
      request,
      "OldValues",
      SqlTypes.MaxNVarChar,
      payload.oldValues ?? null,
    );
    addInput(
      request,
      "NewValues",
      SqlTypes.MaxNVarChar,
      payload.newValues ?? null,
    );

    await request.execute("sp_AuditLog_Create");
  }

  async findAll(filters) {
    const pool = await getPool();
    const request = pool.request();

    addInput(request, "ActorID", SqlTypes.VarChar, filters.actorId ?? null);
    addInput(
      request,
      "ActorRole",
      SqlTypes.NVarChar,
      filters.actorRole ?? null,
    );
    addInput(
      request,
      "ActionType",
      SqlTypes.NVarChar,
      filters.actionType ?? null,
    );
    addInput(
      request,
      "TableName",
      SqlTypes.NVarChar,
      filters.tableName ?? null,
    );
    addInput(
      request,
      "StartDate",
      SqlTypes.DateTime,
      filters.startDate ?? null,
    );
    addInput(request, "EndDate", SqlTypes.DateTime, filters.endDate ?? null);
    addInput(request, "Page", SqlTypes.Int, filters.page ?? 1);
    addInput(request, "Limit", SqlTypes.Int, filters.limit ?? 20);

    const result = await request.execute("sp_AuditLog_List");
    return result.recordset;
  }
}

export const auditRepository = new AuditRepository();
