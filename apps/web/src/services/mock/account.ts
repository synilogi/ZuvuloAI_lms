import type { AccountService } from '../contracts';
import { ServiceError } from '../contracts';
import { respond } from './simulation';

/**
 * The demo build keeps no accounts, so there is nothing to delete: a password the demo's sign-in would
 * accept (6+ characters) confirms, anything shorter is refused the way the API refuses a wrong one.
 */
export const accountService: AccountService = {
  deleteAccount: (password) =>
    respond(() => {
      if (password.length < 6) throw new ServiceError('Your password is not correct.', 'forbidden');
    }, 900),
};
