import { Home } from './pages/home/home';

export interface AppRoute {
    path: string;
    component: any;
}

export type Routes = AppRoute[];

export const routes: Routes = [
    { path: '', component: Home }
];
