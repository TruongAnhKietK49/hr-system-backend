import { sql } from '../config/database.js';

export const addInput = (request, name, type, value) => {
  request.input(name, type, value ?? null);
};

export const SqlTypes = {
  Int: sql.Int,
  VarChar: sql.VarChar,
  NVarChar: sql.NVarChar,
  Date: sql.Date,
  DateTime: sql.DateTime,
  Bit: sql.Bit,
  Decimal18_2: sql.Decimal(18, 2),
  Decimal10_2: sql.Decimal(10, 2),
  MaxNVarChar: sql.NVarChar(sql.MAX),
  MaxVarChar: sql.VarChar(sql.MAX)
};
