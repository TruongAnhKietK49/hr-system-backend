# HR Management Security System Backend

Backend Express + SQL Server cho bài toán HR có RBAC ở mức SQL, stored procedure-first, và salary module riêng cho Director/Finance.

Source of truth hiện tại:

- `sql/init.sql`
- `sql/seed.sql`
- `sql/rbac_employee_procs.sql`

## Tổng quan

Project này dùng flow:

`route -> controller -> service -> repository -> stored procedure`

Mục tiêu chính của version hiện tại:

- không query trực tiếp bảng nhạy cảm trong app code
- employee/salary visibility bám theo stored procedure theo từng role
- salary update tách riêng khỏi employee update
- request payload trả ra API không lộ password raw
- OpenAPI spec được expose trực tiếp từ backend

## Tech stack

- Node.js ESM
- Express
- SQL Server
- `mssql`
- JWT
- `bcryptjs`
- Joi

## Folder structure

```text
src/
  app.js
  server.js
  config/
  middleware/
  constants/
  validations/
  utils/
  docs/
    openapi.js
  modules/
    auth/
    department/
    hr_request/
    approval/
    employee/
    salary/
    finance/
    audit/
    docs/
sql/
  init.sql
  seed.sql
  rbac_employee_procs.sql
tests/
  integration.test.js
docs/
  api.md
```

## Environment variables

Copy `.env.example` sang `.env`:

```bash
copy .env.example .env
```

Giá trị local đang dùng:

```env
PORT=3000
NODE_ENV=development

DB_USER=sa
DB_PASSWORD=123456
DB_SERVER=localhost
DB_PORT=1433
DB_NAME=HRManagementSecuritySystem
DB_ENCRYPT=false
DB_TRUST_SERVER_CERT=true

JWT_SECRET=super-secret-jwt-key
JWT_EXPIRES_IN=1d
JWT_REFRESH_SECRET=super-secret-refresh-key
JWT_REFRESH_EXPIRES_IN=7d
```

## Database setup

Yêu cầu:

- SQL Server chạy ở `localhost:1433`
- account DB có quyền tạo database, procedure, role, symmetric key

Thứ tự chạy script:

1. `sql/init.sql`
2. `sql/seed.sql`
3. `sql/rbac_employee_procs.sql`

Nếu muốn chạy bằng `sqlcmd`:

```bash
sqlcmd -S localhost,1433 -U sa -P 123456 -i sql/init.sql
sqlcmd -S localhost,1433 -U sa -P 123456 -i sql/seed.sql
sqlcmd -S localhost,1433 -U sa -P 123456 -i sql/rbac_employee_procs.sql
```

Ghi chú:

- `init.sql` tạo schema, encryption artifacts, helper function, auth/request/approval/audit procedures.
- `seed.sql` tạo seeded users, salary rows, sample HR requests, sample audit logs.
- `rbac_employee_procs.sql` tạo role DB, deny/grant và toàn bộ employee/salary procedures theo role.

## Chạy backend

```bash
npm install
npm run dev
```

Hoặc:

```bash
npm start
```

## Lưu ý: Để xem doc API bằng swagger cần cài thư viện

```bash
 npm install swagger-ui-express swagger-jsdoc
```

## Truy cập: localhost:3000/api-docs

Health check:

```text
GET /health
```

## Chạy test

Project hiện dùng integration test tự chạy qua HTTP app + SQL Server seed thật:

```bash
npm test
```

Coverage hiện có:

- login cho toàn bộ tài khoản seed
- employee list theo 6 role seed
- employee detail theo role
- salary list/detail theo role
- Director update salary rồi restore dữ liệu seed
- finance payroll alias
- wrong-role blocking
- validation error cho payload sai
- request payload masking
- OpenAPI endpoint availability

## Seeded accounts

Mật khẩu của tất cả account seed: `123456`

| Username      | Role          | EmployeeID | Department |
| ------------- | ------------- | ---------- | ---------- |
| `director01`  | Director      | `EM00001`  | `D004`     |
| `hrmanager01` | HR Manager    | `EM00002`  | `D001`     |
| `hrstaff01`   | HR Staff      | `EM00003`  | `D001`     |
| `finance01`   | Finance Staff | `EM00004`  | `D002`     |
| `manager01`   | Manager       | `EM00005`  | `D003`     |
| `employee01`  | Employee      | `EM00006`  | `D003`     |

## RBAC overview

### Employee module

Proc theo role:

- Employee -> `sp_Employee_GetList_ForEmployee`, `sp_Employee_GetById_ForEmployee`
- Manager -> `sp_Employee_GetList_ForManager`, `sp_Employee_GetById_ForManager`
- HR Staff -> `sp_Employee_GetList_ForHRStaff`, `sp_Employee_GetById_ForHRStaff`
- HR Manager -> `sp_Employee_GetList_ForHRManager`, `sp_Employee_GetById_ForHRManager`
- Finance Staff -> `sp_Employee_GetList_ForFinance`, `sp_Employee_GetById_ForFinance`
- Director -> `sp_Employee_GetList_ForDirector`, `sp_Employee_GetById_ForDirector`

Behavior chính:

- Employee: thấy nhân sự cùng phòng ban, không có salary fields
- Manager: thấy nhân sự trong department mình quản lý, có `Allowance` và `FinalSalary`
- HR Staff: thấy toàn bộ nhân sự trừ `D001`
- HR Manager: thấy toàn bộ nhân sự, không có salary fields
- Finance Staff: thấy toàn bộ nhân sự nhưng nhân sự ngoài Finance bị mask profile, vẫn có `TaxID`, `Allowance`, `FinalSalary`
- Director: thấy toàn bộ nhân sự + salary config/result

### Employee update policy

- Employee -> `sp_Employee_UpdateProfile_ForEmployee`
- HR Staff -> `sp_Employee_UpdateProfile_ForHRStaff`
- HR Manager -> `sp_Employee_UpdateProfile_ForHRManager`

Field scope:

- Employee: `fullName`, `gender`, `dateOfBirth`, `phoneNumber`
- HR Staff: profile basics trong scope nhìn thấy
- HR Manager: profile basics + `departmentId`, `positionId`, `employmentStatus`, `isActive`

### Salary module overview

Proc theo role:

- Finance Staff -> `sp_Salary_GetList_ForFinance`, `sp_Salary_GetByEmployeeId_ForFinance`
- Director -> `sp_Salary_GetList_ForDirector`, `sp_Salary_GetByEmployeeId_ForDirector`, `sp_Salary_Update_ForDirector`

Director salary update:

- input: `baseSalary`, `salaryCoefficient`, `positionCoefficient`, `allowance`, `formulaVersion`
- SQL tính `FinalSalary`
- SQL upsert vào `EmployeeSalaryConfig` và `EmployeeSalaryResult`
- SQL ghi audit log `UPDATE_SALARY`
- nếu employee chưa có salary row thì SQL tự tạo

### Request / Approval notes

- `sp_HRRequest_ListByScope` và `sp_HRRequest_GetByIdByScope` trả `RequestPayload` đã mask password
- `sp_Approval_GetRequestForDirector` là helper riêng để Director approval flow lấy raw payload cần cho password hashing

## Stored procedure strategy

- App chỉ gọi stored procedures qua repository layer
- SQL mới là nơi chốt row-level và field-level policy cho employee/salary
- Không dùng generic employee update cho salary update
- Finance read và salary read đi qua salary procedures riêng

## Swagger / OpenAPI

Location:

- UI: `GET /api-docs`
- JSON spec: `GET /api-docs/openapi.json`
- spec source trong repo: `src/docs/openapi.js`

Tóm tắt thêm xem ở [docs/api.md](docs/api.md).

## API highlights

- `POST /api/auth/login`
- `POST /api/auth/refresh`
- `GET /api/employees`
- `GET /api/employees/:id`
- `PUT /api/employees/:id`
- `GET /api/salaries`
- `GET /api/salaries/:id`
- `PUT /api/salaries/:id`
- `GET /api/finance/payroll`
- `GET /api/finance/payroll/:id`
- `GET /api/hr-requests`
- `POST /api/hr-requests`
- `GET /api/approvals/pending`
- `POST /api/approvals/:requestId/approve`
- `POST /api/approvals/:requestId/reject`
- `GET /api/audit-logs`

## Lưu ý

- Vì app hiện kết nối DB bằng một account chung, phần `DENY/GRANT` trong SQL chủ yếu dùng để chuẩn hóa policy và chặn direct-access pattern ở mức DB design. Row/field-level enforcement thực tế cho app vẫn nằm trong stored procedure logic theo `RequesterEmployeeID`.
- Request tạo employee hiện vẫn lưu password raw trong `HR_Request` để approval flow hash được đúng tại backend. API read path đã mask field này ở SQL, nhưng về lâu dài nên cân nhắc thay đổi design request payload để không phải lưu raw password trong DB.
