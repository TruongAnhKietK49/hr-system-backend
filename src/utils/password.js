import bcrypt from 'bcryptjs';

export const generateHashAndSalt = async (plainPassword) => {
  const salt = await bcrypt.genSalt(10);
  const hash = await bcrypt.hash(plainPassword, salt);
  return { hash, salt };
};

export const verifyPassword = async (plainPassword, hash) => bcrypt.compare(plainPassword, hash);
