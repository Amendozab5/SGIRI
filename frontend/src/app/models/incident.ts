import { EIncidentStatus } from "./EIncidentStatus.enum";

export interface Incident {
  id: number;
  description: string;
  status: EIncidentStatus;
  creatorUsername: string;
  technicianUsername: string | null;
  createdAt: string;
  updatedAt: string;
}