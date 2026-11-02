import type { SettingsRecord, SettingsSection, LmsSettings } from '@syniastrolms/domain';

import type { SettingsService } from '../contracts';
import { get, put } from './client';

export const httpSettings: SettingsService = {
  get: () => get<SettingsRecord>('/settings'),
  save: <S extends SettingsSection>(section: S, value: LmsSettings[S]) => put<SettingsRecord>(`/settings/${section}`, value),
};
