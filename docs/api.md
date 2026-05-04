# API Docs Guide

Project hiện có OpenAPI spec thật được serve từ backend:

- Swagger UI: `GET /api-docs`
- OpenAPI JSON: `GET /api-docs/openapi.json`

Spec source trong code:

- `src/docs/openapi.js`
- route expose docs: `src/modules/docs/docs.routes.js`

## Nhóm endpoint chính

### Auth

- `POST /api/auth/login`
- `POST /api/auth/refresh`

### Employees

- `GET /api/employees`
- `GET /api/employees/:id`
- `PUT /api/employees/:id`

Employee list/detail bám hoàn toàn vào proc SQL theo role:

- Employee -> same department
- Manager -> managed department
- HR Staff -> all except `D001`
- HR Manager -> all employees
- Finance Staff -> masked profile ngoài Finance, vẫn có payroll-safe fields
- Director -> full employee + salary config/result

### Salaries

- `GET /api/salaries`
- `GET /api/salaries/:id`
- `PUT /api/salaries/:id`

Policy:

- Finance Staff: read-only, không thấy `BaseSalary`, `SalaryCoefficient`, `PositionCoefficient`
- Director: read/write đầy đủ salary config/result
- `PUT /api/salaries/:id` chỉ Director gọi được

### Finance

- `GET /api/finance/payroll`
- `GET /api/finance/payroll/:id`

Đây là alias read-only để tương thích, dùng cùng salary procedures với salary module.

### HR Requests / Approvals

- `GET /api/hr-requests`
- `GET /api/hr-requests/:id`
- `POST /api/hr-requests`
- `GET /api/approvals/pending`
- `POST /api/approvals/:requestId/approve`
- `POST /api/approvals/:requestId/reject`

`RequestPayload` ở read endpoints đã được mask password từ SQL.

### Audit

- `GET /api/audit-logs`

## Khi cần update docs

1. Sửa `src/docs/openapi.js`
2. Nếu thêm route mới, gắn route vào `src/app.js`
3. Chạy `npm test`
4. Mở `http://localhost:3000/api-docs` để verify UI/spec
