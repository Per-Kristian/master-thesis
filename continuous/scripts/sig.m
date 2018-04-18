A = 1.3;
B = 0.28;
C = 1;
D = 1;

fnc = @(x) -D+((D.*(1+1./C))./((1./C)+exp(((x-A)./B))));

fplot(fnc, [0 5]);
ylim([-1.5 1.5]);
grid on