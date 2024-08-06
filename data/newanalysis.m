clear;

elapsed_time_s = 2* 60 + 19.093;
KiB = 2^10; % 1024 Bytes
frequency = 10^6 * 40; % 40 MHz
ms_per_s = 10^3;
ns_per_ms = 10^6;


latencytbl = readtable("latencystats.csv");

N = size(latencytbl, 1);
latencytbl.LATENCYMS = (latencytbl.SEC .* ms_per_s) + (latencytbl.NSEC ./ ns_per_ms);
latencytbl.NBYTES = latencytbl.X .* latencytbl.Y .* (latencytbl.BPP / 8);
total_bytes = sum(latencytbl.NBYTES);
kib_per_s = (total_bytes / KiB) / (elapsed_time_s);

throughput_per_image_kib_per_s = (latencytbl.NBYTES ./ KiB) ./ (latencytbl.LATENCYMS ./ ms_per_s);
latency_per_image_ms_per_byte = latencytbl.LATENCYMS ./ latencytbl.NBYTES;
CPU_time = sum(latencytbl.LATENCYMS) / ms_per_s;

disp("Elapsed time (wall clock): " + elapsed_time_s + " s");
disp("Processing time: " + CPU_time + " s");
disp("Core utilization: " + CPU_time / elapsed_time_s + " x");
disp("Bytes processed: " + total_bytes + " B");
disp("Throughput: " + kib_per_s + " KiB/s");
disp("Average latency: " + elapsed_time_s / N + " s/image");
disp("Average latency per byte: " + (elapsed_time_s * ms_per_s) / (total_bytes) + " ms/B");
