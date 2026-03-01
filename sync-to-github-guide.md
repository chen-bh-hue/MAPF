# 将代码同步到 GitHub 的步骤

## 方案一：只同步某个项目文件夹（推荐）

如果只想同步某个项目（如 `catkin_ws`、`ros2_ws`、`copyyy` 等），进入该文件夹操作：

```bash
# 1. 进入你的项目目录（替换成你的实际项目路径）
cd /home/bingda/你的项目名

# 2. 初始化 Git（如果还没有）
git init

# 3. 添加远程仓库（替换成你的 GitHub 仓库地址）
git remote add origin https://github.com/你的用户名/你的仓库名.git

# 4. 添加要提交的文件
git add .

# 5. 首次提交
git commit -m "Initial commit"

# 6. 推送到 GitHub（使用分支 new-nano-6）
git checkout -b new-nano-6
git push -u origin new-nano-6
```

如果 GitHub 仓库已存在且不为空，可能需要先拉取再推送：
```bash
git pull origin new-nano-6 --allow-unrelated-histories
git push -u origin new-nano-6
```

---

## 方案二：在主目录建仓（仅同步部分文件，如配置/脚本）

如果希望在 /home/bingda 下建仓，**务必使用 .gitignore 排除敏感和无关目录**。

### 步骤 1：在 GitHub 上创建新仓库
- 打开 https://github.com/new
- 仓库名自定，选择 Public/Private，**不要**勾选 "Add a README"（避免首次 push 冲突）

### 步骤 2：本地初始化并关联
```bash
cd /home/bingda
git init
git remote add origin https://github.com/你的用户名/你的仓库名.git
```

### 步骤 3：使用 .gitignore 只同步需要的（白名单）
主目录下已有一份 **白名单式** `.gitignore`：
- 默认**忽略根目录下所有内容**（`/*`）
- 只**取消忽略**你想同步的项（以 `!` 开头）

**当前会同步的：** `.gitignore`、`.bashrc`、`.profile`、`.bash_logout`、所有 `*.sh`、`sync-to-github-guide.md`。

**要同步某个目录：** 打开 `/home/bingda/.gitignore`，在「目录」区域把对应行前面的 `#` 去掉，例如：
- `# !Documents/` → `!Documents/`
- `# !catkin_ws/` → `!catkin_ws/`
保存后再执行 `git add .` 和提交即可。

### 步骤 4：添加、提交、推送到分支 new-nano-6
```bash
git add .
git status   # 确认没有误加入敏感文件
git commit -m "Initial commit"
git checkout -b new-nano-6
git push -u origin new-nano-6
```

### 认证方式
- **HTTPS**：推送时输入 GitHub 用户名和 Personal Access Token（不是密码）
- **SSH**：使用 `git@github.com:用户名/仓库名.git`，需先在 GitHub 添加 SSH 公钥（~/.ssh/id_rsa.pub）

---

## 后续日常同步（分支 new-nano-6）
```bash
git checkout new-nano-6   # 若当前不在该分支
git add .
git commit -m "描述本次修改"
git push origin new-nano-6
```
