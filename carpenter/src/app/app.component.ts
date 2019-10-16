import { Component } from '@angular/core';
import { DataSource } from 'src/taekgu/directive/DataSource';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.sass']
})
@DataSource
export class AppComponent {
  title = 'Carpenter';
}
