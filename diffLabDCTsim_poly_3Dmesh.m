% diffLabDCTsim_poly_3Dmesh script simulates the diffraction pattern of polycrystal
% created by Haixing Fang, first established in March 2019

% The present code generates reflections for any space group. If structural
% information is given it can calculate the structure factors. The
% diffraction pattern simulated from a polycrystal either with random orientations or
% orientations input by the user.

%%%% This simulation applies for the polychromatic X-ray generated by W
%%%% anode
%%%% 3D meshing on grains
%%% by default the X-ray spectrum profile corresponds to the X-ray source operating at an electron accelerating voltage of 140 kV 

% Input of grain structures need to be created first using input_main.m
% When first time to run it, simulating only one projection is strongly recommended for testing

% Haixing Fang, hfang@mek.dtu.dk, haixingfang868@gmail.com

clear all;
% close all;
%%% load dipimage, mpt3 and mtex toolbox
load_diplib;
load_mpt3; % see documentation, type 'mptdoc'
load_mtex;

% several examples of input given here
% load(fullfile(strcat(pwd,'\Examples'),'Input_8grains_MeshNr15.mat')); % an experimental LabDCT characterized sample
% load(fullfile(strcat(pwd,'\Examples'),'Grain100um_400_400_600_MeshNr15_input.mat')); % virtual cylindrical sample 400*400*600 um^3, < d > = 100 um
% load(fullfile(strcat(pwd,'\Examples'),'Grain30um_100_100_150_input.mat'));% virtual cylindrical sample 100*100*150 um^3, < d > = 30 um
load(fullfile(strcat(pwd,'\Examples'),'Grain60um_200_200_300_input.mat'));% virtual cylindrical sample 200*200*300 um^3, < d > = 60 um

exp_parameters; % customize the experimental parameters: Lss, Lsd, detector pixel size etc.

% % change to Fe, as an example
% input_fe;
% if readhkl == 0
%     sg = sglib(space_group_IT_number); % get sysconditions for specific element from the sglib.m
%     sysconditions=sg.sysconditions;
% end

tthetamax = acos(dot([Lsam2det 0 0]./norm([Lsam2det 0 0]), ...
    [Lsam2det 0.5*detysize*pixelysize 0.5*detzsize*pixelzsize]./norm([Lsam2det 0.5*detysize*pixelysize 0.5*detzsize*pixelzsize])));
tthetamax = tthetamax*180/pi; % two-theta [deg]
thetamax=tthetamax/2;
lambda_max = 12.39818746/min(Energy);   % [Angstrom]
lambda_min = 12.39818746/max(Energy); % [Angstrom]
Kmax = 1/lambda_min;
Kmin = 1/lambda_max;
lambda = 12.398./Energy;
sintlmax = sin(thetamax*pi/180)/(12.398/Energy(find(I0E==max(I0E)))); % sin(theta)/lambda [A^-1], consider the characteristic wavelength which corresponds to highest flux
Ki_max = [-2*pi/lambda_min 0 0];
Klen_max = -Ki_max(1);
Ki_min = [-2*pi/lambda_max 0 0];
Klen_min = -Ki_min(1);

L = Lsam2det+Lsam2sou; % source-to-detector distance [mm]

B = FormB(cell);
V = cellvolume(cell); % [Angs^3]

emass =9.1093826e-31;
echarge = 1.60217653e-19;
pi4eps0 = 1.11265e-10;
c = 299792458 ;
K1 =  (echarge^2/(pi4eps0*emass*c*c)*1000)^2; % square of Thomson scattering length r0^2, [mm^2]
% Calc the rotation matrix for the detector
if tilt_x ~= 0 || tilt_y ~= 0 || tilt_z ~= 0
    Rx =[1 0 0; 0 cos(tilt_x) -sin(tilt_x); 0 sin(tilt_x) cos(tilt_x)];
    Ry =[cos(tilt_y) 0 sin(tilt_y); 0 1 0; -sin(tilt_y) 0 cos(tilt_y)];
    Rz =[cos(tilt_z) -sin(tilt_z) 0; sin(tilt_z) cos(tilt_z) 0; 0 0 1];
    R = Rx*Ry*Rz;
end

if readhkl == 0
    % Generate Miller indices for reflections within a certain resolution  
    % only compute the first several hkl families
    Ahkl0  = genhkl(cell,sysconditions,1.5*sintlmax);
    hkl_square=Ahkl0(:,1).^2+Ahkl0(:,2).^2+Ahkl0(:,3).^2;
    hkl_square=sortrows(unique(hkl_square));
    Ahkl=[];
    hklnumber=4; % maximum is 10, recommended be at least >= 4
    if length(hkl_square(:,1))>=hklnumber
        hkl2_max=hkl_square(hklnumber);
    else
        hkl2_max=hkl_square(end);
    end
    for i=1:length(Ahkl0(:,1))
        if (Ahkl0(i,1).^2+Ahkl0(i,2).^2+Ahkl0(i,3).^2)<=hkl2_max
            Ahkl=[Ahkl;Ahkl0(i,:)];
        end
    end
      
    % Initialize Ahkl
    nrhkl = size(Ahkl,1);
    if structfact == 1
        disp('Calculating Structure factors');
        atomlib;
        hkl = [0 0 0];
        for i=1:nrhkl
            hkl2 = [Ahkl(i,1) Ahkl(i,2) Ahkl(i,3)];            
            if all(hkl2 == -1*hkl) %Only calculate F^2 if not Friedel mate 
                hkl = hkl2;
            else
                hkl = hkl2;
                [Freal Fimg] = structure_factor(hkl,cell,atomparam,sg,atom);
                int = Freal^2 + Fimg^2;
            end
            Ahkl(i,5) = int;
        end
        %disp('Finished Calculating Structure factors'); disp(' ')
    else
        for i=1:nrhkl
            Ahkl(i,5) = 32768; % half of 2^16
        end
    end
else
    disp('Please set readhkl as 0 for automatic generation of hkl reflections ');
end
% save([direc,'/Ahkl.mat'],'Ahkl','-MAT')

rot_number=1; % recording number of rotations
rot_start=-180;
rot_end=180;
rot_step=2;
frame_number=rot_start:(rot_end-rot_start)/5:rot_end; % frame number to display
frame_showno=1;
% parpool;
% delete(gcp);
% for rot =rot_start:rot_step:rot_end % rotation angle, a full dataset
% for rot =rot_start:2*rot_step:0 % rotation angle, every 2*rot_step projs
for rot = [-146]  % one projection
    AllSpotsNr(rot_number)=0; % number of all spots
    SpotOverlapNr(rot_number)=0; % number of overlapped spots
    rotation_angle(rot_number)=rot;

    S=[1 0 0;0 -1 0;0 0 1];
    Sw=S;
    Ss=S;
    omega=rot*pi/180; % [rad]
    Omega=[cos(omega) -sin(omega) 0;sin(omega) cos(omega) 0;0 0 1]; 

    graininfo = zeros(abs(grains),16);
    A=[];
    % Generate orientations of the grains and loop over all grains
     for grainno = 1:abs(grains)
%      for grainno = [4 5 6 7 8]
        if rot_number==1
            hkl_color=[255 0 0;0 255 0;0 0 255;255 255 0;0 255 255;255 0 255;0 128 0;128 0 128;0 0 128;255 140 0];
            % hkl color: red, green, blue, yellow, cyan, magenta, olive,
            % purple, navy, dark orange
            hklnumber_max(grainno)=hklnumber;
            if hklnumber>=5
                if grainsize(grainno)>=200
                    hklnumber_max(grainno)=hklnumber;
                elseif grainsize(grainno)>=150 && grainsize(grainno)<200
                    hklnumber_max(grainno)=min([hklnumber 8]);
                elseif grainsize(grainno)>=120 && grainsize(grainno)<150
                    hklnumber_max(grainno)=min([hklnumber 6]);
                else
                    hklnumber_max(grainno)=4;
                end
            end
        end
        phi1 = euler_grains(grainno,1)*pi/180;
        Phi = euler_grains(grainno,2)*pi/180;
        phi2 = euler_grains(grainno,3)*pi/180;
        U = euler2u(phi1,Phi,phi2);
        if exist('Su','var')==1
            U=Su{grainno}*U; % for transformation when needed
        end
        if exist('Suu','var')==1
            U=Suu*U; % for transformation when needed
        end
        graininfo(grainno,1:6) = [grainno grainsize(grainno) grainvolume(grainno) phi1*180/pi Phi*180/pi phi2*180/pi];
        graininfo(grainno,7:15) = [U(1,1) U(1,2) U(1,3) U(2,1) U(2,2) U(2,3) U(3,1) U(3,2) U(3,3)];
        graininfo(grainno,16)=length(SubGrain{grainno}(:,1)); % number of 3D cells for calculation
        reshape(graininfo(grainno,7:15),3,3)';
        
        nr = 1;
        nrefl = 1;
        % Calculate matrix A with (1:totalnr, 2:grain, 3:refno, 4-6:h,k,l, 7:F^2, 8:phi1, 9:PHI, 10:phi2,
        % 11-13:Gw(1),Gw(2),Gw(3), 14:omega, 15:2theta, 16:eta, 17:dety, 18:detz, 19:Lorentz, 20:Polarization, 21:Int)
        % Gw is the G-vector in the omega-system (w=0)
        % Gt is the G-vector in the tilted system (identical to the lab-system except for the tilt of sample stage)
        % All angles in A are in degrees
        SubA{grainno}=[];
        for subgrainno=1:length(SubGrain{grainno}(:,1))           
            %diffraction center
            SubGrain_pos=[SubGrain{grainno}(subgrainno,2) SubGrain{grainno}(subgrainno,3) SubGrain{grainno}(subgrainno,4)];
            SubGrain_posW=Omega*Ss*SubGrain_pos';
            center = [L, SubGrain_posW(2)*L/(Lsam2sou+SubGrain_posW(1)), ...
                SubGrain_posW(3)*L/(Lsam2sou+SubGrain_posW(1))]; % sample center projected to the position of the detector
            center0 = [L, SubGrain_pos(2)*L/(Lsam2sou+SubGrain_pos(1)), ...
                SubGrain_pos(3)*L/(Lsam2sou+SubGrain_pos(1))];
            alpha = atan(sqrt(SubGrain_posW(2)^2+SubGrain_posW(3)^2)/(Lsam2sou+SubGrain_posW(1)));
            grainpos = [Lsam2sou+SubGrain_posW(1) SubGrain_posW(2) SubGrain_posW(3)];
%             K_in = [Lsam2sou+SubGrain_posW(1) SubGrain_posW(2) SubGrain_posW(3)];
            for j=1:nrhkl
                if (Ahkl(j,1)^2+Ahkl(j,2)^2+Ahkl(j,3)^2)<=hkl_square(hklnumber_max(grainno))
                hkl = [Ahkl(j,1) Ahkl(j,2) Ahkl(j,3)]';
                Gw = Sw*U*B*hkl;
                Gt=Omega*Gw;
                v1 = [0 Gt(2) Gt(3)];
                Glen = (Gt(1)^2 + Gt(2)^2 + Gt(3)^2)^0.5;
                beta = acos(dot(grainpos/norm(grainpos),Gt/Glen)); % [rad]
                if beta > pi/2 && beta < (90+thetamax*4)/180*pi
                    theta = beta-pi/2;
                    sintth = sin(2*theta);
                    costth = cos(2*theta);
                    d = 1/Glen*2*pi;
                    lambdahkl = 2 * d *sin(theta);
                    Energy_hkl=12.398/lambdahkl; % [keV]
                    if lambdahkl > lambda_min && lambdahkl < lambda_max
                        phix = acos(dot(v1/norm(v1),center/norm(center)));
                        phiy = phix-2*theta;
                        L2 = (Lsam2det-SubGrain_posW(1))/cos(alpha);
                        diffvec = L2*sintth/sin(phiy); % [mm]
                        Kd = Ki_max + Gt';
                        shkl = norm(Kd)-Klen_max;
                            if shkl == 0.0
                                ds = 1;
                            else
                                ds = (sin(pi*shkl)/(pi*shkl))^2;
                            end
                            SubA{grainno}(nr,1) = nr;
                            SubA{grainno}(nr,2) = grainno;
                            SubA{grainno}(nr,3) = nrefl;
                            SubA{grainno}(nr,4:6) = hkl';
                            SubA{grainno}(nr,7) = Ahkl(j,5);
                            SubA{grainno}(nr,8) = phi1*180/pi;
                            SubA{grainno}(nr,9) = Phi*180/pi;
                            SubA{grainno}(nr,10) = phi2*180/pi;
                            SubA{grainno}(nr,11:13) = Gt';
                            SubA{grainno}(nr,14) = rot;% omega [deg]
                            SubA{grainno}(nr,15)= 2*theta*180/pi;
                            
                            eta=atan2(Gt(3),-Gt(2)); % [0, -pi] and [0, pi]
                            if eta>0
                                eta=eta-pi/2;
                                if eta<0
                                    eta=eta+2*pi;
                                end
                            else
                                eta=eta+3/2*pi;
                            end
                            SubA{grainno}(nr,16) = eta*180/pi;% [0 360] eta [deg]                            
                            % angle between PQ vector and the vertical
                            % axis, modified on Feb 26, 2020
                            eta=acos(dot([0 Gt(2) Gt(3)]/norm([0 Gt(2) Gt(3)]),[0 0 1]/norm([0 0 1])));
                            SubA{grainno}(nr,16) = eta*180/pi;% [0 360] eta [deg]                            
                            SubA{grainno}(nr,23) = subgrainno;
                            konst = norm([0 Gt(2) Gt(3)]);

                            dety22 = (center(2)+ (diffvec*Gt(2)/konst)); % dety [mm]
                            detz22 = (center(3)+ (diffvec*Gt(3)/konst)); % detz [mm]
                            dety2=dety0+dety22/pixelysize;
                            detz2=detz0+detz22/pixelzsize;

                            SubA{grainno}(nr,17) = dety2;
                            SubA{grainno}(nr,18) = detz2;                            
                            %%%%%% Lorentz factor
%                           Lorentz=1;
                            Lorentz=1./(sin(theta).^2.*cos(theta));
                            SubA{grainno}(nr,19)=Lorentz;
                            %%%%%% Polarisation
%                             P=1; % for synchrontron source, polarization is normally perpendicular to plane of scattering
                            P=(1+costth^2)/2; % for lab X-ray producing unpolarized X-ray beam
                            SubA{grainno}(nr,20)=P;

                            %Diffracted intensity
                            SubA{grainno}(nr,21)=0;
                            ee=min(find(Energy>(Energy_hkl-(Energy(2)-Energy(1))) & Energy<(Energy_hkl+(Energy(2)-Energy(1)))));
                                if SubGrain{grainno}(subgrainno,6)==Inf % few cases of the polydehron in the grain volume is Inf due to meshing
                                    SubGrain{grainno}(subgrainno,6)=mean(setdiff(SubGrain{grainno}(:,6),Inf,'rows'));
                                end
                                if SubGrain{grainno}(subgrainno,6)>1 && SubGrain{grainno}(subgrainno,6)<400 % identify unit as um
                                    K2(ee) = lambda(ee)^3*SubGrain{grainno}(subgrainno,5)*10^12/V^2; % [dimensionless]
                                else
                                    K2(ee) = lambda(ee)^3*SubGrain{grainno}(subgrainno,5)*10^21/V^2; % [dimensionless] % identify unit as mm
                                end
                                SubA{grainno}(nr,21) = SubA{grainno}(nr,21)+K1*K2(ee)*abs(I0E(ee))*Lorentz*P*Ahkl(j,5)*ExpTime; % intensity [photons]
                                if Lorentz==1
                                    SubA{grainno}(nr,21)=SubA{grainno}(nr,21)*2e3; % a factor, no physical meaning
                                end
                                SubA{grainno}(nr,22) = Energy_hkl;
                    end % Loop over possible 2-theta range
                end
                end
                nr = nr+1;
                nrefl = nrefl+1;
           end % Loop over reflections       
        end % Loop over subgrains
        
        SubA_eff{grainno}=[];
        if ~isempty(SubA{grainno})
            for kk=1:length(SubA{grainno}(:,1))
                if (~(all(SubA{grainno}(kk,:))==0) || SubA{grainno}(kk,21)>0) ...
                        && (SubA{grainno}(kk,17)>=1 && SubA{grainno}(kk,17)<=detzsize ...
                        && SubA{grainno}(kk,18)>=1 && SubA{grainno}(kk,18)<=detysize)
                    SubA_eff{grainno}=[SubA_eff{grainno};SubA{grainno}(kk,:)]; % select the data contributing to the intensity on the detector
                end
            end
        end
        A=[A;SubA_eff{grainno}];
    end % loop over grains
    bgint_gen; % generate background noise, move to here on March 25,2020
    thres1=bgint+sqrt(bgint);
    %Make diffraction images
    if makeframes == 1
        peakshape=1; % recommended to employ Gaussian point spread
        makeimage_poly_3Dmesh_v3;
    else
        disp('Diffraction images are not formed ... Set makeframes equal to 1 for generating images.')
    end
    
    % check DA and TFT folders exist
    if ~exist('TFT', 'dir')
       mkdir('TFT'); % TFT folder is to store each output projection
       direc = 'TFT';  % save frames in this directory
    else
	   direc = 'TFT';
    end
    if ~exist('DA', 'dir')
       mkdir('DA'); % DA folder is to store data record for each projection
    end
    
    A_rot{rot_number}=A;
    header_A_rot = ['ReflectionNo.' ' ' 'GrainNo.' ' ' 'NumberOfReflection' ' ' 'h' ' ' 'k' ' ' 'l' ' ' 'F^2' ' ' ...
        'phi1' ' ' 'Phi' ' ' 'phi2' ' ' 'Gw(1)' ' ' 'Gw(2)' ' ' 'Gw(3)' ' ' 'Omega' ' ' '2-theta' ' ' ...
        'eta' ' ' 'det_y' ' ' 'det_z' ' ' 'LorentzFactor' ' ' 'PolarizationFactor' ' ' 'IntegratedIntensity' ...
        ' ' 'EnergyHKL' ' ' 'Subgrainno'];
    if ~isempty(A_rot{rot_number})
        fid=fopen(strcat('DA\',strcat(num2str(rot_number-1),'A_rot.txt')),'wt');
        fprintf(fid, [header_A_rot '\n']);
        for pp=1:length(A_rot{rot_number}(:,1))
            fprintf(fid, '%d %d %d %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %d\n', A_rot{rot_number}(pp,:));
        end
        fclose(fid);
    end
    if exist('GrainIndex','var')
        A_GrainIndex{rot_number}=GrainIndex;
        header_A_GrainIndex = ['SpotID' ' ' 'SpotSize' ' ' 'GrainID' ' ' 'h' ' ' 'k' ' ' 'l' ...
            ' ' 'AverageIntensiy' ' ' 'ReflectionNo' ' ' 'OverlapFraction' ' ' 'IntegratedIntensity'];
        if ~isempty(A_GrainIndex{rot_number})
            fid=fopen(strcat('DA\',strcat(num2str(rot_number-1),'GrainIndex.txt')),'wt');
            fprintf(fid, [header_A_GrainIndex '\n']);
            for pp=1:length(A_GrainIndex{rot_number}(:,1))
                fprintf(fid, '%d %d %d %d %d %d %f %d %d %f\n', A_GrainIndex{rot_number}(pp,:));
            end
            fclose(fid);
        end
        A_GrainIndex_unique{rot_number}=GrainIndex_unique;
        if ~isempty(A_GrainIndex_unique{rot_number})
            fid=fopen(strcat('DA\',strcat(num2str(rot_number-1),'GrainIndex_unique.txt')),'wt');
            fprintf(fid, [header_A_GrainIndex '\n']);
            for pp=1:length(A_GrainIndex_unique{rot_number}(:,1))
                fprintf(fid, '%d %d %d %d %d %d %f %d %d %f\n', A_GrainIndex_unique{rot_number}(pp,:));
            end
            fclose(fid);
        end
    end
    
%     if ismember(rot,frame_number)
%         subplot(2,3,frame_showno);
%         imshow(frame_image,[0 2^16-1],'Colormap',grey);
%         hold on;
%         for k = 1:30:size(frame_image,1)
%             plot([size(frame_image,1)/2 size(frame_image,1)/2],[1 k],'Color','w','LineStyle','-');
%             plot([size(frame_image,1)/2 size(frame_image,1)/2],[1 k],'Color','k','LineStyle',':');
%             plot([1 k],[size(frame_image,1)/2 size(frame_image,1)/2],'Color','w','LineStyle','-');
%             plot([1 k],[size(frame_image,1)/2 size(frame_image,1)/2],'Color','k','LineStyle',':');
%         end
%         hold off;
%         title(['rotation = ',num2str(frame_number(frame_showno)),' deg']);
%         frame_showno=frame_showno+1;
%     end
    rot_number=rot_number+1;
    rot
end % loop over rotations
% dipshow(frame_image);
dipshow(frame_image_BeamStop);
if exist('frame_label_annot','var')
    dipshow(frame_label_annot);
end

% save graininfo
header_graininfo = ['GrainNo.' ' ' 'GrainDiameter' ' ' 'GrainVolume' ' ' 'EulerAngle(phi1)' ' ' 'EulerAngle(Phi)' ...
    ' ' 'EulerAngle(phi2)' ' ' 'U11' ' ' 'U12' ' ' 'U13' ' ' 'U21' ' ' 'U22' ' ' 'U23' ' ' ...
    'U31' ' ' 'U32' ' ' 'U33' ' ' 'SubGrainNo'];
if ~isempty(graininfo)
    fid=fopen(strcat(pwd,'\DA\graininfo.txt'),'wt');
    fprintf(fid, [header_graininfo '\n']);
    for i=1:length(graininfo(:,1))
        fprintf(fid, '%d %f %f %f %f %f %f %f %f %f %f %f %f %f %f %d\n', graininfo(i,:));
    end
    fclose(fid);
end
% save('Result.mat','-v7.3');






