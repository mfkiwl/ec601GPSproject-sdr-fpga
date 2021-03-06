%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Author: Josh Wildey
%  Class: AAE57500
%  Homework 5 - 12/2/2011
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all
clear all
clc

format long
%%%%%%%%% Problem 1: %%%%%%%%%
load eph.dat
load rcvrc.dat

x_rx = [-2701206.38; -4293642.366; 3857878.924];   %[m]  Initial Position Guess (given)
tb_R = 0;                       %[s]  Initial Guess in receiver clock bias
x_hat = [.6; .6; .6; 0];           % Initialize x_hat for while loop control

% Display Initial Guess
disp('Estimate of Position:')
fprintf('X Position: %f\n',x_rx(1))
fprintf('Y Position: %f\n',x_rx(2))
fprintf('Z Position: %f\n',x_rx(3))
fprintf('t_b:        %f\n\n',tb_R)

rcvrc_tow = rcvrc(:,1);         %[s]  Receiver Time of Week
svid = rcvrc(:,2);              %[]  Satellite Vehicle ID
pr = rcvrc(:,3);                %[m]  Pseudorange
c = 299792458;                  %[m/s]  Speed of Light

toc = eph(:,3);                 %[s]  Time of Clock
toe = eph(:,4);                 %[s]  Time of Applicability
I_0 = eph(:,15);                %[rad]  Orbital Inclination
omega_dot = eph(:,16);          %[rad/s]  Rate of Right Ascen
e = eph(:,9);                   %[]  Eccentricity
sqrt_a = eph(:,10);             %[m^.5]  SQRT(A)
omega_0 = eph(:,14);            %[rad]  Right Ascen at TOA
omega = eph(:,13);              %[rad]  Argument of Perigee
M_0 = eph(:,12);                %[rad]  Mean Anom
delta_n = eph(:,11);            %[rad/s]  mean motion diff
I_dot = eph(:,17);              %[rad/s]  Rate of inclin
Cuc = eph(:,19);                %[rad]  lat cosine ampl
Cus = eph(:,18);                %[rad]  radius sin ampl
Crc = eph(:,23);                %[m]  inclin cos ampl
Crs = eph(:,22);                %[m]  radius sin ampl
Cic = eph(:,21);                %[rad]  inclin cos ampl
Cis = eph(:,20);                %[rad]  inclin sin ampl
omega_dot_e = 7.2921151467e-5;  %[rad/sec] Number from IS-GPS-200E
mu = 3.986005e14;               %[m^3/s^2] Number from IS-GPS-200E

t = rcvrc_tow(1);
Y = pr;
I = eye(4);

while (abs(x_hat(1))>.5 && abs(x_hat(2))>.5 && abs(x_hat(3))>.5)
    
    tau = (pr - c.*tb_R)./c;  %[s]  Time delay of Satellite Signal
    t_tx = t - tau;         %[s]  Time of transmission
    t_k = t_tx - toe;          % Time from ephemeris refence time
    
    A_k = sqrt_a.^2;  % Semi-Major Axis
    n_0 = sqrt(mu./A_k.^3);  %[rad/s]  Computed Mean Motion
    n = n_0 + delta_n;  % Correct Mean Motion
    M_k = M_0 + n.*t_k;  % Mean Anomaly
    
    E_k = kepler_E(e,M_k);  % Eccentric Anomaly
    v_k = 2*atan(sqrt((1+e)./(1-e)).*tan(E_k./2));  % True Anomaly
    
    phi_k = v_k + omega;  % Argument of latitude
    % Second Harmonic Perturbations
    delta_u_k = Cus.*sin(2.*phi_k) + Cuc.*cos(2.*phi_k);  % Argument of latitude Correction
    delta_r_k = Crs.*sin(2.*phi_k) + Crc.*cos(2.*phi_k);  % Radial Correction
    delta_i_k = Cis.*sin(2.*phi_k) + Cic.*cos(2.*phi_k);  % Inclination Correction
    
    u_k = phi_k + delta_u_k;               % Corrected Argument of Latitude
    r_k = A_k.*(1-e.*cos(E_k)) + delta_r_k;  % Corrected Radius
    i_k = I_0 + I_dot.*t_k + delta_i_k;   % Corrected Inclination
    
    % Positions in Orbital plane
    x_kprime = r_k.*cos(u_k);
    y_kprime = r_k.*sin(u_k);
    
    % Corrected Longitude of Ascending Node
    omega_k = omega_0 + (omega_dot - omega_dot_e).*t_k - omega_dot_e.*toe;
    
    % Earth Fixed Coordinates of SV antenna phase center
    x_k = x_kprime.*cos(omega_k) - y_kprime.*cos(i_k).*sin(omega_k);
    y_k = x_kprime.*sin(omega_k) + y_kprime.*cos(i_k).*cos(omega_k);
    z_k = y_kprime.*sin(i_k);
    
    % Satellite Position at the time of reception
    x_k_rx = cos(omega_dot_e.*tau).*x_k + sin(omega_dot_e.*tau).*y_k;
    y_k_rx = -sin(omega_dot_e.*tau).*x_k + cos(omega_dot_e.*tau).*y_k;
    z_k_rx = z_k;

    R = sqrt((x_k- x_rx(1)).^2 + (y_k-x_rx(2)).^2 + (z_k-x_rx(3)).^2);
    
    H = [(x_rx(1) - x_k_rx(1))/R(1), (x_rx(2) - y_k_rx(1))/R(1), (x_rx(3) - z_k_rx(1))/R(1) 1;
         (x_rx(1) - x_k_rx(2))/R(2), (x_rx(2) - y_k_rx(2))/R(2), (x_rx(3) - z_k_rx(2))/R(2) 1;
         (x_rx(1) - x_k_rx(3))/R(3), (x_rx(2) - y_k_rx(3))/R(3), (x_rx(3) - z_k_rx(3))/R(3) 1;
         (x_rx(1) - x_k_rx(4))/R(4), (x_rx(2) - y_k_rx(4))/R(4), (x_rx(3) - z_k_rx(4))/R(4) 1;
         (x_rx(1) - x_k_rx(5))/R(5), (x_rx(2) - y_k_rx(5))/R(5), (x_rx(3) - z_k_rx(5))/R(5) 1;
         (x_rx(1) - x_k_rx(6))/R(6), (x_rx(2) - y_k_rx(6))/R(6), (x_rx(3) - z_k_rx(6))/R(6) 1;
         (x_rx(1) - x_k_rx(7))/R(7), (x_rx(2) - y_k_rx(7))/R(7), (x_rx(3) - z_k_rx(7))/R(7) 1;
         (x_rx(1) - x_k_rx(8))/R(8), (x_rx(2) - y_k_rx(8))/R(8), (x_rx(3) - z_k_rx(8))/R(8) 1;];
     
     M = linsolve(H',I');
     M = M';
     
     h = [(R(1) + c*tb_R); (R(2) + c*tb_R); (R(3) + c*tb_R); (R(4) + c*tb_R);
          (R(5) + c*tb_R); (R(6) + c*tb_R); (R(7) + c*tb_R); (R(8) + c*tb_R);];
      
     y = Y - h;
     
     x_hat = M*y;
     
     x_rx = x_rx + x_hat(1:3);
     tb_R = tb_R + x_hat(4)/c;
     
     disp('Estimate of Position:')
     fprintf('X Position: %f\n',x_rx(1))
     fprintf('Y Position: %f\n',x_rx(2))
     fprintf('Z Position: %f\n',x_rx(3))
     fprintf('t_b:        %f\n\n',tb_R)
    
end

lla = ecef2lla([x_rx(1) x_rx(2) x_rx(3)], 'WGS84');

disp('Geodetic Coordinates:')
fprintf('Latitude:  %f\n',lla(1))
fprintf('Longitude: %f\n',lla(2))
fprintf('Altitude:  %f\n\n',lla(3))

% Geometry matrix:
G = inv(H'*H);

%GDOP
GDOP = sqrt(trace(G));
%PDOP
PDOP = sqrt(G(1,1) + G(2,2)+ G(3,3));
%TDOP
TDOP = sqrt(G(4,4));

disp('Dilution of Position')
fprintf('GDOP: %f\n',GDOP)
fprintf('PDOP: %f\n',PDOP)
fprintf('TDOP: %f\n',TDOP)

%  Plot Position of Satellites and Receiver around Earth
figure(1)
hold on
title('Satellite and Receiver Positions')
plot3(x_k,y_k,z_k,'*')
plot3(x_rx(1),x_rx(2),x_rx(3),'r*')
legend('Satellite Position','Receiver Position')
earth_sphere('m')
grid on
hold off