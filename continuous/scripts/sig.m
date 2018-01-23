A = 2;
B = 0.35;
C = 1;
D = 1;

fnc = @(x) -D+((D.*(1+1./C))./((1./C)+exp(((x-A)./B))));

fplot(fnc, [0 5]);
ylim([-2 2]);
grid on