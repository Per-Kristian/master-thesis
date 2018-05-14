A = 1.85;
B = 0.28;
C = 1.1;
%D = 1;

%fnc = @(x) -D+((D.*(1+1./C))./((1./C)+exp(((x-A)./B))));
fnc = @(x) -C+((C.*2)./(1+exp((x-A)./B)));

fplot(fnc, [0 5]);
title(sprintf('A = %.1f, B = %.1f, C = %.1f', A, B, C));
xlabel('Score (sc)');
ylabel('\Delta_{T}(sc)');
ylim([-1.5 1.5]);
grid on