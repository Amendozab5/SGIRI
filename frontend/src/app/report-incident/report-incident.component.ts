import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { IncidentService } from '../_services/incident.service';
import { IncidentRequest } from '../models/incident-request';

@Component({
  selector: 'app-report-incident',
  templateUrl: './report-incident.component.html',
  styleUrls: ['./report-incident.component.css'],
  standalone: true,
  imports: [CommonModule, FormsModule]
})
export class ReportIncidentComponent implements OnInit {

  form: IncidentRequest = {
    description: ''
  };
  isSuccessful = false;
  isReportFailed = false;
  errorMessage = '';

  constructor(private incidentService: IncidentService) { }

  ngOnInit(): void {
  }

  onSubmit(): void {
    this.incidentService.createIncident(this.form).subscribe({
      next: (data: any) => {
        console.log(data);
        this.isSuccessful = true;
        this.isReportFailed = false;
        this.form = { description: '' }; // Reset form on success
      },
      error: (err: any) => {
        this.errorMessage = err.error.message || err.statusText;
        this.isReportFailed = true;
        this.isSuccessful = false;
      }
    });
  }
}