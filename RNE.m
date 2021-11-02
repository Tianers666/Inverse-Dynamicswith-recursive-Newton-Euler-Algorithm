%% Recursive Newton-Euler Algorithm for dynamic model of serial robots with modified DH parameters.
%% Take iiwa7 as example.
function tau_list = RNE(q,qd,qdd,G)
%% ���������
% q������ؽ����꣬�˴�Ϊ�ؽ�ת�ǣ�1��7����ÿһ��������Ӧһ��ؽ�ת�ǣ���λ��rad��
% qd�� ����ؽ�����һ�׵������˴�Ϊ�ؽڽ��ٶȣ�1��7����ÿһ��������Ӧһ��ؽڽ��ٶȣ���λ��rad/s��
% qdd�� ����ؽ�������׵������˴�Ϊ�ؽڽǼ��ٶȣ�1��7����ÿһ��������Ӧһ��ؽڽǼ��ٶȣ���λ��rad/s^2��
% G���������G = 1,������Ӱ�죬��G = 0,������Ӱ�죻
% note:��������������ĳ����豣��һ�¡�

%% ���������
% tau_list ���ؽ����أ�1��7����ÿһ��������Ӧһ��ؽ����أ���λ��Nm

% �ж������Ƿ���Ϲ���
rows = size(q,1);
if rows ~= size(qd,1) || rows ~= size(qdd,1)
    error("����������Ȳ�һ��");
end

% ������ʼ��
% DH_list��������DH������4��7����
%          alpha      a     d     theta
dh_list = [0          0    0.34     0;
           -pi/2      0    0        0;
           pi/2       0    0.4      0;
           -pi/2      0    0        0;
           pi/2       0    0.4      0;
           -pi/2      0    0        0;
           pi/2       0    0.1266   0;
           0          0    0        0];
       
% mass_list: ���˵�������1��7���󣬵�λ��kg       
mass_list = [2702.4 2725.8 3175.01 2725.80 1693.85 1836.74 269.17]/1000;

% mass_center_list��������������������ϵ�µ�λ�ã�3��7���󣬵�λ��m                             
%                   x         y           z
mass_center_list = [0        -34.73       -69.48;
                    0        -67.33       34.41;
                    -0.03    29.56        -89.00;
                    0.03     -67.33       -34.41;
                    0        -21.39       -140.03;
                    0        -2.12        0.29;
                    0.01      0           -25.22]/1000;
                
% inertia_tensor_list�����˹�����������ϵ�Ĺ�����������������ϵ����������ϵ��λһ�£�7��3��3���󣬵�λkg*m^2
%         I                =      Ixx            -Ixy           -Ixz
%                                 -Ixy           Iyy            -Iyz
%                                 -Iyz           -Iyz           Izz
inertia_tensor_list(:,:,1) = [17085955.96       29.13           520.90;
                              29.13             16299848.40     3041655.32;
                              520.90            3041655.32      6028717.92]/1e9;
                          
inertia_tensor_list(:,:,2) = [17049081.74       -379.65         -251.02;
                              -379.65           6095392.93      2836636.56;
                              -251.02           2836636.56      16245722.28]/1e9;
                          
inertia_tensor_list(:,:,3) = [25077403.67       1373.03         4792.34;
                              1373.03           23806776.16     -4872887.52;
                              4792.34           -4872887.52      7607337.29]/1e9;
                          
inertia_tensor_list(:,:,4) = [17049008.27       -2836.83        605.34;
                              -2836.83           6095457.66      2836684.49;
                              605.34            2836684.49      16245750.37]/1e9; 
                          
inertia_tensor_list(:,:,5) = [10079214.34       -74.51          17.98;
                              -74.51             8702598.01      3090329.67;
                              17.98             3090329.67      4469563.66]/1e9;
                          
inertia_tensor_list(:,:,6) = [5094485.23        -96.90           -67.21;
                              -96.90            3542620.51      -249580.52;
                              -67.21            -249580.52      4899002.53]/1e9;
                          
inertia_tensor_list(:,:,7) = [198764.02         0.88            -27.71;
                              0.88              195312.12       0.20;
                              -27.71            0.20            322516.91]/1e9;
                          
% f_external��ʩ����ĩ�����˵�������������
f_external = zeros(2,3);

number_of_links = 7;
z = [0,0,1]';  % �ؽ���
%%�ж��Ƿ�ʩ������
if G == 1
    g = 9.81;     % �������ٶȣ���λm/s^2
else
    g = 0;
end

% λ�˱任�����������
for i = 1:number_of_links+1
    dh = dh_list(i,:);
    alpha(i) = dh(1);
    a(i) = dh(2);
    d(i) = dh(3);
    theta(i) = dh(4);
    if i == number_of_links+1
        q(i) = 0;
    end
    T(:,:,i) = [cos(q(i)),            -sin(q(i)),           0,           a(i);
            sin(q(i))*cos(alpha(i)), cos(q(i))*cos(alpha(i)), -sin(alpha(i)), -sin(alpha(i))*d(i);
            sin(q(i))*sin(alpha(i)), cos(q(i))*sin(alpha(i)), cos(alpha(i)), cos(alpha(i))*d(i);
            0,                     0,                     0,          1];
    T = T(:,:,i);
    % ��ȡ��ת��������
    R(:,:,i) = inv(T(1:3,1:3));
    P(:,:,i) = T(1:3,4:4);
end

for k = 1: rows
    % ���� --->
    for i = 0:number_of_links-1
        if i == 0
            wi = [0,0,0]';      % ��ʼ���ٶ�Ϊ0
            dwi = [0,0,0]';     % ��ʼ�Ǽ��ٶ�Ϊ0
            dvi = [0, 0, g]';   % ��ʼ���ٶȣ���������ϵ0���������ٶȷ����������
        else
            wi = w(:,i);
            dwi = dw(:,i);
            dvi = dv(:,i);
        end
        w(:,:,i+1) = R(:,:,i+1)*wi + qd(k,i+1)*z;
        dw(:,:,i+1) = R(:,:,i+1)*dwi + cross(R(:,:,i+1)*wi,qd(k,i+1)*z) + qdd(k,i+1)*z;
        dv(:,:,i+1) = R(:,:,i+1)*(cross(dwi,P(:,:,i+1)) + cross(wi,cross(wi,P(:,:,i+1))) + dvi);
        dvc(:,:,i+1) = cross(dw(:,:,i+1),mass_center_list(i+1,:)')...
                        + cross(w(:,:,i+1),cross(w(:,:,i+1),mass_center_list(i+1,:)'))...
                        + dv(:,:,i+1);
        F(:,:,i+1) = mass_list(i+1)*dvc(:,:,i+1);
        N(:,:,i+1) = inertia_tensor_list(:,:,i+1)*dw(:,:,i+1) + cross(w(:,:,i+1),inertia_tensor_list(:,:,i+1)*w(:,:,i+1));
    end
    % ���� <---
    for i = number_of_links:-1:1
        if i == number_of_links
            f(:,:,i+1) = f_external(1,:)';
            n(:,:,i+1) = f_external(2,:)';
        end
        f(:,:,i) = R(:,:,i+1)\f(:,:,i+1) + F(:,:,i);
        n(:,:,i) = N(:,:,i) + R(:,:,i+1)\n(:,:,i+1) + cross(mass_center_list(i,:)',F(:,:,i))...
                    + cross(P(:,:,i+1),R(:,:,i+1)\f(:,:,i+1));
        tau_list (k,i) = dot(n(:,:,i),z);
    end
end
