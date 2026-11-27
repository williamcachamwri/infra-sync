# Pull Shark CI 🦈

Repository **Private** chạy GitHub Actions định kỳ để tự động tạo nhánh, commit, mở Pull Request và merge an toàn (có giãn cách chống Secondary Rate Limit & tự dừng khi đủ mốc **Pull Shark Gold `1,024` PR**).

## Thiết lập bắt buộc (1 lần duy nhất - ~1 phút)

### Bước 1: Bật tính thành tựu từ Private Repo trên GitHub Profile
GitHub mặc định chỉ đếm hoạt động Public trừ khi bạn bật tuỳ chọn này:
1. Mở **[GitHub Profile Settings](https://github.com/settings/profile)**.
2. Kéo xuống mục **Contributions & activity**.
3. Tick chọn ✅ **Include private contributions on my profile** *(Show private contributions and achievements on my profile)* rồi bấm **Save** (hoặc bật trực tiếp tại nút **Contribution settings** ngay phía trên biểu đồ xanh ở trang cá nhân).

### Bước 2: Tạo Fine-grained PAT & lưu vào Secret `GH_PAT`
> **Lưu ý quan trọng:** Nếu dùng `GITHUB_TOKEN` mặc định của Actions, người tạo PR sẽ là `github-actions[bot]` nên **không được tính** vào badge của `@williamcachamwri`. Bạn cần dùng PAT cá nhân giới hạn đúng trong repo này:

1. Mở **[Fine-grained Personal Access Tokens](https://github.com/settings/personal-access-tokens/new)**:
   - **Token name:** `pull-shark-ci`
   - **Repository access:** Chọn **Only select repositories** -> chọn `williamcachamwri/pull-shark-ci`.
   - **Permissions -> Repository permissions:**
     - `Contents`: **Read and write**
     - `Pull requests`: **Read and write**
   - Bấm **Generate token** và copy mã `github_pat_...`.
2. Thêm secret vào repo bằng terminal (hoặc tại [Actions Secrets](https://github.com/williamcachamwri/pull-shark-ci/settings/secrets/actions)):
   ```powershell
   gh secret set GH_PAT -R williamcachamwri/pull-shark-ci
   ```
   *(Dán token vừa copy rồi nhấn Enter).*

## Cách hoạt động & Tuỳ chỉnh
- **Tự động theo lịch (`schedule`):** Chạy 2 lần/ngày lúc `10:17` và `22:43` (giờ VN), mỗi lần `10` PR (`20` PR/ngày) -> mất ~5 ngày để lên **Pull Shark Silver (`x3 - 128`)** và tự động dừng hẳn khi chạm mốc **Pull Shark Gold (`x4 - 1,024+`)**.
- **Chạy thủ công bất kỳ lúc nào:**
  ```powershell
  gh workflow run pull-shark.yml -R williamcachamwri/pull-shark-ci -f batch_size=15
  ```
- **Cày gộp luôn `Pair Extraordinaire Gold` (`48` PR):** Đặt thêm Repository Variable `COAUTHOR_TRAILER` (ví dụ `Friend Name <friend@users.noreply.github.com>`) tại `Settings -> Secrets and variables -> Actions -> Variables`.
