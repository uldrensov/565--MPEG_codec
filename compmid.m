function m = compmid(a,b,n)
f=@(x) .4 .* x.^3 .* cos(x.^4);
xact = integral(f,a,b); %exact solution

h = (b-a) / n; %subdivision width
i = 1:n; %subdivision counter
ci = a + .5*h * ((2*i)-1); %x-value of midpoint of subdivision

m = h*sum(f(ci)); %width * all heights of interest
error = abs(abs(xact) - abs(m));
fprintf("Absolute error: %d\n",error);
end