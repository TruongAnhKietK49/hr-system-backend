import express from "express";
import cors from "cors";
import helmet from "helmet";

import swaggerUi from "swagger-ui-express";

import { logger } from "./middleware/logger.js";
import { errorHandler } from "./middleware/error.js";

import authRoutes from "./modules/auth/auth.routes.js";
import departmentRoutes from "./modules/department/department.routes.js";
import requestRoutes from "./modules/hr_request/request.routes.js";
import approvalRoutes from "./modules/approval/approval.routes.js";
import employeeRoutes from "./modules/employee/employee.routes.js";
import financeRoutes from "./modules/finance/finance.routes.js";
import salaryRoutes from "./modules/salary/salary.routes.js";
import auditRoutes from "./modules/audit/audit.routes.js";
import docsRoutes from "./modules/docs/docs.routes.js";

const app = express();

app.use(
  helmet({
    contentSecurityPolicy: false,
  }),
);

app.use(cors());
app.use(express.json());
app.use(logger);

app.get("/health", (req, res) => {
  res.json({ success: true, message: "Server is running" });
});

app.use("/api/auth", authRoutes);
app.use("/api/departments", departmentRoutes);
app.use("/api/hr-requests", requestRoutes);
app.use("/api/approvals", approvalRoutes);
app.use("/api/employees", employeeRoutes);
app.use("/api/salaries", salaryRoutes);
app.use("/api/finance", financeRoutes);
app.use("/api/audit-logs", auditRoutes);
app.use("/api-docs", docsRoutes);

app.use(errorHandler);

export default app;
