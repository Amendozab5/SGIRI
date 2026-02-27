import { NgModule, provideBrowserGlobalErrorListeners } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule } from '@angular/forms';
import { HttpClientModule } from '@angular/common/http';

import { AppRoutingModule } from './app-routing-module';
import { App } from './app'; // Keep import for bootstrap
import { LoginComponent } from './login/login.component';
import { RegisterComponent } from './register/register.component'; // Import RegisterComponent
import { HomeComponent } from './home/home.component';
import { BoardAdminComponent } from './boards/board-admin/board-admin.component';
import { BoardTechnicianComponent } from './boards/board-technician/board-technician.component';
import { BoardUserComponent } from './boards/board-user/board-user.component';

import { authInterceptorProviders } from './_helpers/auth.interceptor';

@NgModule({
  imports: [
    BrowserModule,
    AppRoutingModule,
    FormsModule,
    HttpClientModule,
    App // Import standalone App component
  ],
  providers: [
    provideBrowserGlobalErrorListeners(),
    authInterceptorProviders
  ],
  bootstrap: [App]
})
export class AppModule { }
