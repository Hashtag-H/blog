INSERT INTO category (name, slug, description, sort)
VALUES
  ('深度学习', 'deep-learning', '深度学习、神经网络、生成模型与工程实践笔记。', 40),
  ('名言赏析', 'quote-notes', '把经典句子拆开，放回日常学习与长期成长中理解。', 50)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  sort = EXCLUDED.sort,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO tag (name, slug, description)
VALUES
  ('深度学习', 'deep-learning', 'Deep learning notes.'),
  ('CNN', 'cnn', 'Convolutional neural networks.'),
  ('Transformer', 'transformer', 'Transformer and attention mechanisms.'),
  ('训练技巧', 'training-tricks', 'Optimization, debugging, and training practice.'),
  ('扩散模型', 'diffusion-models', 'Diffusion models and generative AI.'),
  ('生成式 AI', 'generative-ai', 'Generative AI learning notes.'),
  ('学习方法', 'learning-method', 'Learning methods and study reflections.'),
  ('名言赏析', 'quote-notes', 'Quote appreciation and reflection.'),
  ('好奇心', 'curiosity', 'Curiosity and scientific thinking.'),
  ('孔子', 'confucius', 'Classical Chinese learning quotes.')
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO article (
  title, slug, summary, cover_url, content_markdown, content_html,
  category_id, status, is_top, allow_recommendation,
  seo_title, seo_description, word_count, reading_minutes, published_at
)
VALUES
(
  '卷积神经网络：从直觉到 PyTorch 实现',
  'deep-learning-cnn-from-intuition-to-pytorch',
  '用图像识别的例子理解卷积、感受野、池化、通道与特征图，并给出一个可以继续扩展的 PyTorch 训练骨架。',
  '/images/generated/deep-learning-cnn-cover.png',
  $md$
## 为什么 CNN 适合图像

图像不是一串互不相关的数字。相邻像素之间往往共享边缘、纹理、颜色过渡和空间结构。卷积神经网络的核心优势，就是把这种局部性变成可学习的参数：一个小卷积核在整张图上滑动，反复寻找相似的局部模式。

如果全连接网络直接处理一张 224 x 224 x 3 的图片，第一层就会产生巨量参数，而且它不知道“左上角的边缘”和“右下角的边缘”其实可以共享同一套识别方式。CNN 用局部连接和权重共享解决这个问题。

## 卷积核在学什么

可以把卷积核想象成一张小小的滤镜。浅层卷积核常常学习边缘、角点、颜色块；中层开始组合出纹理、局部形状；深层则更接近语义结构，比如眼睛、轮廓、车轮或者建筑边缘。

卷积层的输出叫特征图。一个通道对应一种检测器的响应强弱，多通道叠在一起，就像给图片做了一组可学习的观察笔记。

## 感受野与层级抽象

单个 3 x 3 卷积核只看很小一片区域，但多层堆叠后，后面的神经元能够间接看到更大的图像区域，这就是感受野逐渐扩大的过程。

这也是 CNN 的层级抽象能力来源：

1. 第一层看边缘。
2. 中间层看局部组合。
3. 后面层看更完整的结构。

这个过程很像人读图：先看到线条，再看到形状，最后理解对象。

## 池化不是必须，但很有用

池化层会降低空间分辨率，让特征更紧凑，也能带来一定的位置不敏感性。现在很多模型会用步幅卷积、全局平均池化等方式替代传统池化，但“逐步压缩空间、增强语义”的思想仍然保留着。

## 一个简洁的 PyTorch 骨架

```python
import torch
from torch import nn

class TinyCNN(nn.Module):
    def __init__(self, num_classes=10):
        super().__init__()
        self.features = nn.Sequential(
            nn.Conv2d(3, 32, kernel_size=3, padding=1),
            nn.BatchNorm2d(32),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(2),
            nn.Conv2d(32, 64, kernel_size=3, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(2),
        )
        self.classifier = nn.Sequential(
            nn.AdaptiveAvgPool2d(1),
            nn.Flatten(),
            nn.Linear(64, num_classes),
        )

    def forward(self, x):
        x = self.features(x)
        return self.classifier(x)
```

这个模型不追求复杂，而是保留了 CNN 的几个关键部件：卷积、归一化、非线性、下采样和分类头。初学时先把每一层的输入输出尺寸打印出来，比直接背结构更有效。

## 调试建议

- 先在小数据集上过拟合几十张图片，确认模型有学习能力。
- 观察 loss 是否下降，准确率是否比随机猜测高。
- 检查输入归一化是否和预训练模型要求一致。
- 不要一开始就堆很深，先让一个小模型稳定跑通。

## 小结

CNN 的美感在于简单：小卷积核、权重共享、层级特征。理解它不需要先记住所有经典网络结构，先把“局部模式如何被反复发现和组合”想清楚，就已经走在正确的路上。
$md$,
  NULL,
  (SELECT id FROM category WHERE slug = 'deep-learning'),
  'PUBLISHED',
  TRUE,
  TRUE,
  '卷积神经网络：从直觉到 PyTorch 实现',
  'CNN 入门、卷积核、感受野、特征图与 PyTorch 实现笔记。',
  1150,
  6,
  TIMESTAMPTZ '2026-07-14 21:00:00+08'
),
(
  'Transformer 注意力机制：为什么模型需要“看上下文”',
  'transformer-attention-context-note',
  '从 token、Query、Key、Value 到多头注意力，解释 Transformer 如何把上下文关系转成可学习的权重。',
  '/images/generated/transformer-attention-cover.png',
  $md$
## 从一句话开始理解注意力

当我们读“苹果掉在地上，因为它熟了”这句话时，会自然把“它”指向“苹果”。模型如果只按顺序读字符，很难稳定捕捉这种跨位置关系。注意力机制的目标，就是让每个位置都能主动观察其它位置，并决定哪些信息更重要。

Transformer 的突破并不是“记忆力特别好”，而是给模型提供了一种高效的上下文检索方式。

## Query、Key、Value 的直觉

可以把注意力想象成一次检索：

- Query：当前位置想问什么。
- Key：其它位置能提供什么索引。
- Value：真正被取回的信息内容。

Query 和 Key 做相似度计算，得到注意力分数；分数经过 softmax 后，变成对 Value 的加权求和。于是，一个 token 不再只携带自己的局部含义，也会混入它认为重要的上下文。

## 自注意力在做什么

自注意力里的“自”，指 Query、Key、Value 都来自同一个序列。也就是说，句子中的每个 token 都会和句子里的其它 token 建立关系。

这带来两个好处：

1. 长距离依赖更容易被捕捉。
2. 计算可以并行，不需要像 RNN 那样一步一步传递状态。

当然，代价也很明显：标准注意力的计算量会随序列长度平方增长。因此长上下文模型通常需要稀疏注意力、滑动窗口、KV Cache、低秩近似等工程优化。

## 多头注意力为什么有用

单个注意力头只能从一种角度观察上下文。多头注意力则像让几位同学同时读一段话：有人关注语法关系，有人关注指代关系，有人关注主题线索，有人关注局部搭配。

最后把多个头的结果拼接再投影，模型就获得了更丰富的关系表达。

## 位置编码不可少

注意力本身并不知道顺序。如果没有位置编码，“我喜欢机器学习”和“机器学习喜欢我”在集合意义上会过于相似。位置编码把顺序信息注入 token 表示，常见做法包括正弦位置编码、可学习位置编码、RoPE 等。

## 实践中的观察点

- 训练时关注显存，因为注意力矩阵很容易变大。
- 推理时关注 KV Cache，它决定长文本生成速度。
- 微调时关注学习率和 warmup，Transformer 对训练日程很敏感。
- 做可解释性分析时，可以可视化注意力权重，但不要把它等同于完整解释。

## 小结

注意力机制的关键不是神秘公式，而是“让每个位置根据上下文重新组织自己”。Transformer 把这种组织方式做成了可并行、可堆叠、可扩展的结构，因此成为今天大模型的基础骨架。
$md$,
  NULL,
  (SELECT id FROM category WHERE slug = 'deep-learning'),
  'PUBLISHED',
  FALSE,
  TRUE,
  'Transformer 注意力机制：为什么模型需要看上下文',
  '用直觉解释 Query、Key、Value、多头注意力和位置编码。',
  1080,
  6,
  TIMESTAMPTZ '2026-07-13 19:30:00+08'
),
(
  '训练深度网络不迷路：Loss、学习率与过拟合排查清单',
  'training-deep-networks-debug-checklist',
  '整理深度学习训练时最常见的故障排查路径：loss 不降、震荡、过拟合、欠拟合、数据泄漏与学习率选择。',
  '/images/generated/training-deep-nets-cover.png',
  $md$
## 先让模型能过拟合

训练一个深度网络时，最有效的第一步不是调大模型，而是拿一小批数据做过拟合测试。比如只取 32 或 64 个样本，看看模型能否把训练 loss 降到很低。

如果连小数据都学不会，问题通常不在模型容量，而在数据、标签、损失函数、输出维度或训练循环。

## Loss 不下降时先查什么

可以按这个顺序排查：

1. 输入是否被正确归一化。
2. 标签类型是否和损失函数匹配。
3. 模型输出维度是否正确。
4. optimizer 是否真的拿到了需要训练的参数。
5. 是否忘记调用 `loss.backward()` 或 `optimizer.step()`。
6. 学习率是否过大或过小。

很多训练问题并不高级，只是某个基础环节悄悄断了。

## 学习率是第一调参旋钮

学习率太大，loss 会震荡甚至变成 NaN；学习率太小，loss 下降缓慢，看起来像没有学习。一个实用习惯是先从较小模型开始，用学习率扫描找一个大致可用范围，再考虑 batch size、weight decay、scheduler。

常见组合：

- AdamW + warmup + cosine decay。
- SGD + momentum + step decay。
- 小数据集上适当增大 weight decay 或增强数据增广。

## 过拟合与欠拟合

如果训练集表现很好、验证集表现很差，说明模型记住了训练数据，却没有学到可泛化规律。可以尝试：

- 更强的数据增广。
- weight decay。
- dropout。
- early stopping。
- 减小模型容量。

如果训练集和验证集都很差，则更像欠拟合。可以尝试更大模型、更长训练时间、更好特征或更合适的损失函数。

## 数据泄漏比模型错误更危险

数据泄漏会让指标看起来漂亮，但部署后迅速失效。比如训练集和验证集存在重复样本，或者特征里包含了答案的变体。深度学习项目里，数据切分策略和模型结构一样重要。

## 记录实验，而不是凭感觉调参

每次实验至少记录：

- 数据版本。
- 模型结构。
- 学习率和 scheduler。
- batch size。
- 训练轮数。
- 验证指标。
- 失败现象和猜测。

当实验多起来，记录就是你的第二大脑。没有记录的调参，很快会变成绕圈。

## 小结

训练深度网络像调一台复杂但诚实的机器。它不会告诉你哪里错了，但 loss、梯度、指标和样本可视化会不断给线索。把排查流程固定下来，比背更多技巧更重要。
$md$,
  NULL,
  (SELECT id FROM category WHERE slug = 'deep-learning'),
  'PUBLISHED',
  FALSE,
  TRUE,
  '训练深度网络不迷路：Loss、学习率与过拟合排查清单',
  '深度学习训练排查清单，覆盖 loss、学习率、过拟合和数据泄漏。',
  1040,
  5,
  TIMESTAMPTZ '2026-07-12 20:10:00+08'
),
(
  '扩散模型入门：从加噪到去噪的生成式 AI 直觉',
  'diffusion-models-denoising-intuition',
  '用“逐步加噪、学习去噪、反向生成”的直觉理解扩散模型，并解释它为什么适合图像生成。',
  '/images/generated/diffusion-models-cover.png',
  $md$
## 生成图像为什么可以从噪声开始

扩散模型听起来反直觉：模型不是从草图开始画图，而是从一团噪声开始，逐步把噪声还原成有结构的图像。

它的训练过程可以分成两个方向：

1. 正向过程：把真实图片一步步加噪，直到接近纯噪声。
2. 反向过程：学习每一步如何去掉一点噪声。

如果模型学会了每个阶段的去噪方向，那么推理时就能从随机噪声出发，逐步生成一张清晰图像。

## 模型到底预测什么

常见扩散模型并不是直接预测最终图片，而是预测当前图像里的噪声成分，或者预测与噪声等价的速度变量。训练目标通常是让模型识别“这一步应该去掉哪些噪声”。

这让复杂的图像生成问题被拆成许多小步骤，每一步都相对简单。

## 条件生成：文字如何影响图像

文本到图像模型会把提示词编码成条件信息，再在去噪过程中不断影响图像结构。可以把提示词看成一张路线图，模型每去掉一层噪声，都会参考这张路线图判断应该保留什么、强化什么、舍弃什么。

这也是为什么提示词会影响主体、风格、构图和氛围。

## 为什么扩散模型质量高

扩散模型的优势在于生成过程稳定、细节逐步形成，比较适合处理纹理、光影和复杂场景。它的缺点是推理步骤多，速度天然比单步生成慢。因此后来出现了 DDIM、蒸馏、Latent Diffusion 等加速思路。

Latent Diffusion 的关键是：不在原始像素空间生成，而是在更小的潜空间里去噪，最后再解码成图像。这样既保留质量，也节省计算。

## 学习路线

建议按这个顺序学习：

1. 理解高斯噪声和马尔可夫过程的直觉。
2. 看懂正向加噪公式。
3. 理解 U-Net 为什么适合去噪。
4. 学习文本条件和 cross-attention。
5. 再看采样器、CFG、LoRA 和 ControlNet。

## 小结

扩散模型的核心不在“魔法生成”，而在“学会沿着噪声退场的方向行走”。当你把它看成一条从混沌回到结构的路径，很多公式会变得更容易理解。
$md$,
  NULL,
  (SELECT id FROM category WHERE slug = 'deep-learning'),
  'PUBLISHED',
  FALSE,
  TRUE,
  '扩散模型入门：从加噪到去噪的生成式 AI 直觉',
  '扩散模型、加噪去噪、文本条件生成与 Latent Diffusion 入门。',
  1030,
  5,
  TIMESTAMPTZ '2026-07-11 18:20:00+08'
),
(
  '名言赏析：学而不思则罔，思而不学则殆',
  'quote-learning-and-thinking-confucius',
  '赏析“学而不思则罔，思而不学则殆”：学习需要输入，也需要消化；思考需要自由，也需要材料。',
  '/images/generated/quote-learning-patience-cover.png',
  $md$
## 原句

“学而不思则罔，思而不学则殆。”

这句话出自《论语》，短短十二个字，把学习和思考之间的张力讲得很透。

## 只学习不思考，为什么会“罔”

“罔”可以理解为迷惘。一个人如果只是不断收集知识、摘抄观点、收藏课程，却没有把它们放进自己的问题里检验，就很容易获得一种虚假的充实感。

笔记越来越多，判断却没有变清楚；材料越来越厚，行动却越来越迟疑。这就是只输入、不消化带来的迷惘。

## 只思考不学习，为什么会“殆”

“殆”有危险、疲困的意味。思考当然重要，但如果长期脱离材料、事实和他人经验，思考就会在自己的小房间里打转。

很多看似深刻的想法，其实只是因为读得太少，尚未遇到更好的问题和更严谨的表达。

## 对今天的启发

这句话很适合放到现代学习场景里：

- 看论文时，不只划重点，也要复述问题、方法和限制。
- 学编程时，不只看教程，也要自己改一段、跑一次、错一次。
- 做研究时，不只堆实验，也要问为什么这个实验能支持结论。
- 写博客时，不只搬运资料，也要写出自己的理解路径。

## 一个实用循环

可以把学习拆成四步：

1. 输入：读书、听课、查文档。
2. 整理：摘出概念、例子和问题。
3. 思考：比较、质疑、建立联系。
4. 输出：写作、讲解、实践、复盘。

四步不断循环，知识才会从“见过”变成“能用”。

## 小结

真正的学习不是让大脑变成仓库，而是让它变成工作台。材料要进来，问题要摆开，工具要上手，最后才能做出属于自己的理解。
$md$,
  NULL,
  (SELECT id FROM category WHERE slug = 'quote-notes'),
  'PUBLISHED',
  FALSE,
  TRUE,
  '名言赏析：学而不思则罔，思而不学则殆',
  '孔子名言赏析，讨论学习、思考、输入和输出。',
  820,
  4,
  TIMESTAMPTZ '2026-07-10 21:10:00+08'
),
(
  '名言赏析：知之者不如好之者，好之者不如乐之者',
  'quote-curiosity-joyful-learning',
  '赏析“知之者不如好之者，好之者不如乐之者”：从知道、喜欢到乐在其中，是长期主义学习的三层台阶。',
  '/images/generated/quote-curiosity-science-cover.png',
  $md$
## 原句

“知之者不如好之者，好之者不如乐之者。”

这句话同样出自《论语》。它讲的不是学习技巧，而是学习状态的层次。

## 第一层：知之

“知之”是知道。知道一个概念，能复述一个定义，能完成一道题，这是学习的开始。很多考试型学习会停在这一层，因为它足够应付短期目标。

但知道并不等于稳定掌握。只要换一种问法、换一个场景，知识可能就变得陌生。

## 第二层：好之

“好之”是喜欢。喜欢会带来主动性。你会愿意多看一个例子，多问一句为什么，多尝试一种实现方式。

在深度学习里，喜欢会让人从“模型能跑就行”继续追问：为什么这个 loss 下降更稳定？为什么这个结构泛化更好？为什么这个数据集让指标虚高？

## 第三层：乐之

“乐之”是乐在其中。到这一层，学习不只是为了完成任务，而是变成一种能量来源。你会在解决问题、发现联系、表达清楚的时候感到愉快。

这并不意味着学习永远轻松。恰恰相反，真正的乐趣常常来自困难被慢慢拆开的过程。

## 对技术学习的启发

技术成长很难只靠意志力硬撑。更稳定的方式，是把学习设计成能持续获得反馈的系统：

- 选择一个真实问题。
- 做出一个可运行的小版本。
- 记录卡住的地方。
- 写一篇复盘。
- 再改进一轮。

当反馈变清楚，兴趣就更容易被保护下来。

## 小结

从“知道”到“喜欢”，再到“乐在其中”，不是天赋筛选，而是状态培养。一个人能走多远，往往取决于他能不能在长期练习中找到一点稳定的欢喜。
$md$,
  NULL,
  (SELECT id FROM category WHERE slug = 'quote-notes'),
  'PUBLISHED',
  FALSE,
  TRUE,
  '名言赏析：知之者不如好之者，好之者不如乐之者',
  '孔子名言赏析，讨论兴趣、好奇心与长期学习。',
  800,
  4,
  TIMESTAMPTZ '2026-07-09 20:00:00+08'
)
ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title,
  summary = EXCLUDED.summary,
  cover_url = EXCLUDED.cover_url,
  content_markdown = EXCLUDED.content_markdown,
  content_html = EXCLUDED.content_html,
  category_id = EXCLUDED.category_id,
  status = EXCLUDED.status,
  is_top = EXCLUDED.is_top,
  allow_recommendation = EXCLUDED.allow_recommendation,
  seo_title = EXCLUDED.seo_title,
  seo_description = EXCLUDED.seo_description,
  word_count = EXCLUDED.word_count,
  reading_minutes = EXCLUDED.reading_minutes,
  published_at = EXCLUDED.published_at,
  updated_at = CURRENT_TIMESTAMP,
  deleted = FALSE;

DELETE FROM article_tag
WHERE article_id IN (
  SELECT id FROM article
  WHERE slug IN (
    'deep-learning-cnn-from-intuition-to-pytorch',
    'transformer-attention-context-note',
    'training-deep-networks-debug-checklist',
    'diffusion-models-denoising-intuition',
    'quote-learning-and-thinking-confucius',
    'quote-curiosity-joyful-learning'
  )
);

INSERT INTO article_tag (article_id, tag_id)
SELECT a.id, t.id
FROM (
  VALUES
    ('deep-learning-cnn-from-intuition-to-pytorch', 'deep-learning'),
    ('deep-learning-cnn-from-intuition-to-pytorch', 'cnn'),
    ('deep-learning-cnn-from-intuition-to-pytorch', 'training-tricks'),
    ('transformer-attention-context-note', 'deep-learning'),
    ('transformer-attention-context-note', 'transformer'),
    ('transformer-attention-context-note', 'generative-ai'),
    ('training-deep-networks-debug-checklist', 'deep-learning'),
    ('training-deep-networks-debug-checklist', 'training-tricks'),
    ('training-deep-networks-debug-checklist', 'learning-method'),
    ('diffusion-models-denoising-intuition', 'diffusion-models'),
    ('diffusion-models-denoising-intuition', 'generative-ai'),
    ('diffusion-models-denoising-intuition', 'deep-learning'),
    ('quote-learning-and-thinking-confucius', 'quote-notes'),
    ('quote-learning-and-thinking-confucius', 'learning-method'),
    ('quote-learning-and-thinking-confucius', 'confucius'),
    ('quote-curiosity-joyful-learning', 'quote-notes'),
    ('quote-curiosity-joyful-learning', 'curiosity'),
    ('quote-curiosity-joyful-learning', 'confucius')
) AS pairs(article_slug, tag_slug)
JOIN article a ON a.slug = pairs.article_slug
JOIN tag t ON t.slug = pairs.tag_slug
ON CONFLICT DO NOTHING;
