export const success = (res, data = null, message = 'Success', statusCode = 200, meta = null) => {
  return res.status(statusCode).json({ success: true, message, data, meta });
};

export const error = (res, message = 'Error', statusCode = 500) => {
  return res.status(statusCode).json({ success: false, message });
};
