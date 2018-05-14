A = 2;
B = 0.3;
C = 60.001;

%fnc = @(x) -D+((D.*(1+1/C))./((1./C)+exp((x-A)./B)));
%fnc = @(x) -D+((D.*2)./(1+exp((x-A)./B)));
fnc = @(x) -C+((C.*2)./(1+exp((x-A)./B)));

fplot(fnc, [0 5]);
ylim([-65 65]);
title(sprintf('A = %.1f, B = %.1f, C = %.3f', A, B, C));
xlabel('Score (sc)');
ylabel('\Delta_{T}(sc)');
grid on