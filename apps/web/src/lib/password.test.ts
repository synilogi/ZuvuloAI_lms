import { describe, expect, it } from 'vitest';
import { generatePassword } from './password';

describe('a generated password', () => {
  it('is long, and mixes every kind of character', () => {
    for (let i = 0; i < 50; i++) {
      const password = generatePassword();
      expect(password).toHaveLength(16);
      expect(password).toMatch(/[a-z]/);
      expect(password).toMatch(/[A-Z]/);
      expect(password).toMatch(/[2-9]/);
      expect(password).toMatch(/[!@#$%*\-_+?]/);
      expect(password).not.toMatch(/[lIO01\s]/);
    }
  });

  it('is never shorter than twelve characters, and differs every time', () => {
    expect(generatePassword(4)).toHaveLength(12);
    expect(new Set(Array.from({ length: 20 }, () => generatePassword())).size).toBe(20);
  });
});
