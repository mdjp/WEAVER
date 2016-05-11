cla
t = 0:1e-4:1;
% ORIG 
x1 = [1+cos(2*pi*50*t)].*cos(2*pi*1000*t);
% modded
x2 = [1+cos(2*pi*50*t)].*sin(2*pi*150*t).*cos(2*pi*1000*t);

figure(1);
% orig unsquared
plot(t,x1)
xlim([0 0.1])
xlabel('Seconds')
%keyboard;
y = hilbert(x1);
env = abs(y);
plot(t,x1)
hold on
plot(t,[1]*env,'r','LineWidth',2)
xlim([0 0.1])
xlabel('Seconds');

figure(2);

plot(t,x1)
xlim([0 0.1])
xlabel('Seconds')
%keyboard;
x1=x1.^2;
y = hilbert(x1);
env = abs(y);
plot(t,x1)
hold on
plot(t,[1]*env,'r','LineWidth',2)
xlim([0 0.1])
xlabel('Seconds');

figure(3);
plot(t,x2)
xlim([0 0.1])
xlabel('Seconds')
%keyboard;
x2=x2.^2;
y = hilbert(x2);
env = abs(y);
plot(t,x2)
hold on
plot(t,[1]*env,'r','LineWidth',2)
xlim([0 0.1])
xlabel('Seconds');

disp('fin');




