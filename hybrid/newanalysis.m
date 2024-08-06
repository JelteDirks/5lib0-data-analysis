clear;

hybrid_elapsed_time_s = 16.920;
user_time_s = 6.471; % For hybrid this was a big difference
KiB = 2^10; % 1024 Bytes
frequency = 10^6 * 40; % 40 MHz
ms_per_s = 10^3;
ns_per_ms = 10^6;

hybridlatency = readtable("hybridlatency.csv");

N = size(hybridlatency, 1);
hybridlatency.LATENCYMS = (hybridlatency.SEC .* ms_per_s) + (hybridlatency.NSEC ./ ns_per_ms);
hybridlatency.NBYTES = hybridlatency.X .* hybridlatency.Y .* (hybridlatency.BPP / 8);
total_bytes = sum(hybridlatency.NBYTES);
kib_per_s = (total_bytes / KiB) / (hybrid_elapsed_time_s);

CPU_time = sum(hybridlatency.LATENCYMS) / ms_per_s;

disp("===HYBRID PARALLEL ===")
disp("Elapsed time (wall clock): " + hybrid_elapsed_time_s + " s");
disp("Processing time: " + CPU_time + " s");
disp("Parallel utilization: " + CPU_time / hybrid_elapsed_time_s + " x");
disp("Bytes processed: " + total_bytes + " B");
disp("Throughput: " + kib_per_s + " KiB/s");
disp("Average latency: " + hybrid_elapsed_time_s / N + " s/image");
disp("Average latency per byte: " + (hybrid_elapsed_time_s * ms_per_s) / (total_bytes) + " ms/B");
disp("Max latency per iamge: " + max(hybridlatency.LATENCYMS) / ms_per_s + " s/image");
disp("Median latency per image: " + median(hybridlatency.LATENCYMS) / ms_per_s + " s/image");
disp("Mean image size: " + mean(hybridlatency.NBYTES) / KiB + " KiB");
disp("Median image size: " + median(hybridlatency.NBYTES) / KiB + "KiB")
disp("======");

figure();
boxplot(hybridlatency.NBYTES ./ KiB);
ylabel("Image size (KiB)");
xticklabels("Hybrid");