h = 1e-3;   % thickness in m
N = 15;     % discretization: polynomial order of interpolants
rho = 2680; lbd = 5.1448e10; mu = 2.6504e10; 

% define and normalize parameters:
II = eye(3).*shiftdim(eye(3), -2); % 4th order "unit tensor"
c = lbd*II + mu*(permute(II, [1 3 4 2]) + permute(II, [1 3 2 4])); % stiffness tensor
c0 = c(1,2,1,2); rho0 = rho; fh0 = sqrt(c0/rho0);  % normalization parameters
rhon = rho/rho0; cn = c/c0; % normalize

% relevant material matrices: 
udof = 1:2; % Lamb [1:2]; SH [3]; coupled [1:3];
cxx = squeeze(cn(1,udof,udof,1));
cxy = squeeze(cn(1,udof,udof,2)); 
cyx = squeeze(cn(2,udof,udof,1));
cyy = squeeze(cn(2,udof,udof,2));
I = eye(size(cxx)); 

% discretization 
[~, Dy_dash] = chebdif(N, 2); % create differentiation matrices
D1 = -2*Dy_dash(:,:,1); % differentiation on unit domain
D2 = 4*Dy_dash(:,:,2);  % second order derivative
Id = eye(size(D1));     % identity matrix for discretization

% define wave operators:
L2 = kron(cxx, Id); L1 = kron(cxy + cyx, D1); L0 = kron(cyy, D2); 
M = kron(rhon*I, Id);
B1 = kron(cyx, Id([1, N], :)); B0 = kron(cyy, D1([1, N], :));

% incorporate BCs:
dofBC = [(0:length(udof)-1)*N+1; (1:length(udof))*N]; % [1, N, N+1, 2*N, 2*N+1, 3*N];
L2(dofBC, :) = 0; L1(dofBC, :) = B1; L0(dofBC, :) = B0; M(dofBC, :) = 0;

% nfix = N+1; fix the bottom uy displacement component (symmetric waves)
% L2(nfix,:) = []; L1(nfix,:) = []; L0(nfix,:) = []; M(nfix,:) = []; 
% L2(:,nfix) = []; L1(:,nfix) = []; L0(:,nfix) = []; M(:,nfix) = [];

%% solve for real frequencies:
kh = linspace(1e-2, 15, 10000).'; % wavenumber*thickness 
whn = nan(length(kh), size(M, 2)); tic 
for ii = 1:length(kh)
    kh0 = kh(ii);
    [wh2] = polyeig((1i*kh0)^2*L2 + (1i*kh0)*L1 + L0, M); 
    % wh2 = eig(-(1i*kh0)^2*L2 - (1i*kh0)*L1 - L0, M, "vector"); % alternative 
    whn(ii,:) = sort(sqrt(wh2));
end
fh = real(whn/2/pi*fh0); fh(fh == 0) = nan;
chron = toc; fprintf('nF: %d, nK: %d, elapsed time: %g, time per point: %g. ms\n', size(fh, 1), size(fh, 2), chron, chron/length(fh(:))*1e3);

% plot wavenumbers:
kkh = kh.*ones(size(fh)); % expand to same size as fh
figure;
plot(kkh/h/1e3, fh/h/1e6, 'k-');
xlim([0, 12]), ylim([0, 6]),
xlabel('k in rad/mm'), ylabel('f in MHz'),

save("matrices.mat", "L0", "L1", "L2", "M");
